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
	"Repeatedly rebuilds the dependency graph and updates every currently-safe, currently-stale
	project, so that a project bumped in one round (e.g. apptive-common picking up Soil's new
	tip) immediately makes its own consumers (e.g. apptive-account, apptive-scheduler) concretely
	resolvable in the next round -- a real, non-placeholder cascade, since by the time round 2
	runs the round-1 commits already exist locally (see GftVersionResolver>>effectiveTipFor:).
	Stops when a round updates nothing. Never pushes. Answers all GftUpdateResults collected
	across every round (including blocked/no-op ones, so the caller can report a full picture)."
	| results maxRounds |
	results := OrderedCollection new.
	maxRounds := 20.
	1 to: maxRounds do: [ :round |
		| graph staleProjectNames roundResults anyApplied |
		graph := GftDependencyGraph build.
		staleProjectNames := graph projects
			select: [ :p | (graph staleOutgoingReferencesOf: p name) isNotEmpty ]
			thenCollect: [ :p | p name ].
		staleProjectNames isEmpty ifTrue: [ ^ results ].
		roundResults := staleProjectNames collect: [ :name |
			self updateProject: (GftProject named: name) usingGraph: graph ].
		results addAll: roundResults.
		anyApplied := roundResults anySatisfy: [ :r | r applied isNotEmpty ].
		anyApplied ifFalse: [ ^ results ] ].
	^ results
]

{ #category : 'updating' }
GftUpdater class >> updateProject: aProject usingGraph: aGraph [
	"Fixes every currently-stale outgoing commit-pinned reference of aProject in one commit
	(if safe -- see #blockersForUpdating:). Applies each edit by recompiling the affected method
	with its existing protocol preserved, then commits once via Iceberg. Never pushes."
	| blockers staleRefs applied skipped |
	blockers := self blockersForUpdating: aProject.
	blockers isEmpty ifFalse: [ ^ GftUpdateResult projectName: aProject name blockers: blockers ].
	staleRefs := aGraph staleOutgoingReferencesOf: aProject name.
	staleRefs isEmpty ifTrue: [ ^ GftUpdateResult projectName: aProject name blockers: #() ].
	applied := OrderedCollection new.
	skipped := OrderedCollection new.
	staleRefs do: [ :ref |
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
		commitId: (aProject iceRepository commitWithMessage: (self commitMessageFor: aProject applied: applied))
]
