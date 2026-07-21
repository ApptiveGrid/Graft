Class {
	#name : 'GftUpdater',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'safety' }
GftUpdater class >> blockersForUpdating: aProject [
	"Safety preconditions that must hold before Graft touches aProject's repository at all:
	it must be on its tracked branch (not detached, not some other WIP branch) and have no
	pre-existing uncommitted changes of its own -- several of the real repos in this ecosystem
	are routinely checked out on feature branches or have unrelated local edits in progress
	(verified 2026-07-19), and Graft must never fold those into its own commit or commit onto
	the wrong branch."
	| repo blockers |
	blockers := OrderedCollection new.
	repo := aProject iceRepository.
	repo ifNil: [ blockers add: 'Kein Iceberg-Repository registriert.'. ^ blockers ].
	repo head isBranch
		ifFalse: [ blockers add: 'Repository steht auf einem losgelösten Commit (detached HEAD), nicht auf einem Branch.' ]
		ifTrue: [
			repo branchName = aProject trackedRef ifFalse: [
				blockers add: 'Repository steht auf Branch ''', repo branchName, ''', nicht auf dem getrackten Branch ''', aProject trackedRef, '''.' ] ].
	repo isModified ifTrue: [
		blockers add: 'Repository hat bereits unabhängige, nicht committete Änderungen -- Graft fasst das nicht an.' ].
	^ blockers
]

{ #category : 'updating' }
GftUpdater class >> commitMessageFor: aProject applied: appliedAssocs [
	| stream |
	stream := String new writeStream.
	stream nextPutAll: 'Bump ', ((appliedAssocs collect: [ :a | a key ]) fold: [ :a :b | a, ', ', b ]), ' in ', aProject name.
	stream cr; cr.
	appliedAssocs do: [ :a | stream nextPutAll: '- ', a key, ' -> ', a value; cr ].
	stream cr; nextPutAll: 'Applied by Graft.'.
	^ stream contents
]

{ #category : 'updating' }
GftUpdater class >> updateAll [
	^ self updateProjects: (GftProject knownProjects collect: [ :p | p name ]) commit: true
]

{ #category : 'updating' }
GftUpdater class >> updateProject: aProject references: refs commit: shouldCommit [
	"Like #updateProject:usingGraph:commit:, but applies exactly the given references (a
	subset of aProject's stale outgoing refs, e.g. hand-picked by the user in the GUI) instead
	of automatically bundling every currently-stale reference of aProject into one commit."
	| blockers applied skipped |
	blockers := self blockersForUpdating: aProject.
	blockers isEmpty ifFalse: [ ^ GftUpdateResult projectName: aProject name blockers: blockers ].
	refs isEmpty ifTrue: [ ^ GftUpdateResult projectName: aProject name blockers: #() ].
	applied := OrderedCollection new.
	skipped := OrderedCollection new.
	refs do: [ :ref |
		| newRef preview |
		newRef := GftVersionResolver effectiveTipFor: ref targetProject.
		newRef
			ifNil: [ skipped add: ref declaredName -> #noKnownTip ]
			ifNotNil: [
				preview := GftBaselineRewriter previewForReference: ref newRef: newRef.
				preview status = #ok
					ifTrue: [
						| existingProtocol |
						existingProtocol := (aProject baselineClass >> preview selector) protocol name.
						aProject baselineClass compile: preview newSource classified: existingProtocol.
						applied add: ref declaredName -> newRef ]
					ifFalse: [ skipped add: ref declaredName -> preview status ] ] ].
	applied isEmpty ifTrue: [ ^ GftUpdateResult projectName: aProject name blockers: #() applied: applied skipped: skipped commitId: nil ].
	^ GftUpdateResult
		projectName: aProject name
		blockers: #()
		applied: applied
		skipped: skipped
		commitId: (shouldCommit
			ifTrue: [ aProject iceRepository commitWithMessage: (self commitMessageFor: aProject applied: applied) ]
			ifFalse: [ nil ])
]

{ #category : 'updating' }
GftUpdater class >> updateProject: aProject usingGraph: aGraph [
	"Convenience: change + commit, the original v1 behaviour."
	^ self updateProject: aProject usingGraph: aGraph commit: true
]

{ #category : 'updating' }
GftUpdater class >> updateProject: aProject usingGraph: aGraph commit: shouldCommit [
	"Convenience: applies ALL of aProject's currently-stale outgoing references. For picking
	specific ones, use #updateProject:references:commit:."
	^ self updateProject: aProject references: (aGraph staleOutgoingReferencesOf: aProject name) commit: shouldCommit
]

{ #category : 'updating' }
GftUpdater class >> updateProjects: aProjectNameCollection commit: shouldCommit [
	"Applies #updateProject:usingGraph:commit: to every project named in aProjectNameCollection
	that currently has fixable stale outgoing pins. When shouldCommit is true this repeats in
	rounds -- rebuilding the graph each time -- so a project bumped in round 1 (e.g. apptive-common
	picking up Soil's new tip) becomes a real, concrete input for round 2 (e.g. apptive-account
	picking up apptive-common's new tip), via GftVersionResolver>>effectiveTipFor: preferring the
	just-created local commit. When shouldCommit is false nothing ever advances (no commit means
	no new tip for anyone to pick up), so it deliberately only ever does a single pass. Never pushes.
	Answers every GftUpdateResult collected (including blocked/no-op ones)."
	| results maxRounds |
	results := OrderedCollection new.
	maxRounds := shouldCommit ifTrue: [ 20 ] ifFalse: [ 1 ].
	1 to: maxRounds do: [ :round |
		| graph staleNames roundResults anyApplied |
		graph := GftDependencyGraph build.
		staleNames := aProjectNameCollection select: [ :name | (graph staleOutgoingReferencesOf: name) isNotEmpty ].
		staleNames isEmpty ifTrue: [ ^ results ].
		roundResults := staleNames collect: [ :name |
			self updateProject: (GftProject named: name) usingGraph: graph commit: shouldCommit ].
		results addAll: roundResults.
		shouldCommit ifFalse: [ ^ results ].
		anyApplied := roundResults anySatisfy: [ :r | r applied isNotEmpty ].
		anyApplied ifFalse: [ ^ results ] ].
	^ results
]

{ #category : 'updating' }
GftUpdater class >> updateReferences: aReferenceCollection commit: shouldCommit [
	"Applies exactly the given references (which may belong to different owner projects),
	one commit per owner project (if shouldCommit), containing only the selected references --
	never the rest of that project's stale pins. This is the fine-grained entry point the GUI
	uses so Norbert can pick exactly which pin(s) to touch instead of an all-or-nothing per
	project (see [[Graft decisions]] -- this was reported as still too coarse even after the
	sidebar/scope redesign: updating one project bundled in a dependency he did not want touched
	yet). Does not cascade rounds -- each reference is applied exactly once, as picked."
	| byProject results |
	byProject := Dictionary new.
	aReferenceCollection do: [ :ref |
		(byProject at: ref ownerProjectName ifAbsentPut: [ OrderedCollection new ]) add: ref ].
	results := OrderedCollection new.
	byProject keysAndValuesDo: [ :projectName :refs |
		results add: (self updateProject: (GftProject named: projectName) references: refs commit: shouldCommit) ].
	^ results
]
