Class {
	#name : 'GftUpdater',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'safety' }
GftUpdater class >> blockersForUpdating: aProject [
	"Hard safety preconditions that must hold before Graft touches aProject's repository at
	all: it must have no pre-existing uncommitted changes UNRELATED to its own BaselineOf
	package. Several of the real repos in this ecosystem routinely have unrelated local edits
	in progress (verified 2026-07-19), and Graft must never fold those into its own commit.

	Deliberately does NOT block just because the repository is modified at all: Graft's own
	previous change-only edit (commit checkbox off, see Graft decisions) leaves the BaselineOf
	package dirty on purpose, so a second single-pin update on the same project can build on it.
	Only a dirty package OTHER than the project's own BaselineOf package is treated as
	unrelated, pre-existing work Graft must not touch.

	Being on the wrong branch (or detached HEAD) is deliberately NOT a hard blocker here either
	anymore (Norbert 2026-07-21: he often wants a dependency-bump update on its own branch
	rather than Graft insisting on the tracked ref) -- see #needsBranchDecision:/
	#switchToUpdateBranch:for:, which the GUI uses to ask before proceeding on an unexpected
	branch, instead of silently committing there or refusing outright."
	| repo blockers baselinePackageName otherModifiedPackages |
	blockers := OrderedCollection new.
	repo := aProject iceRepository.
	repo ifNil: [ blockers add: 'Kein Iceberg-Repository registriert.'. ^ blockers ].
	baselinePackageName := aProject baselineClassName.
	otherModifiedPackages := repo modifiedPackages reject: [ :pkg | pkg name = baselinePackageName ].
	otherModifiedPackages isEmpty ifFalse: [
		blockers add: 'Repository hat bereits unabhängige, nicht committete Änderungen in: ',
			((otherModifiedPackages collect: [ :p | p name ]) fold: [ :a :b | a, ', ', b ]),
			' -- Graft fasst das nicht an.' ].
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

{ #category : 'safety' }
GftUpdater class >> currentBranchDescriptionFor: aProject [
	| repo |
	repo := aProject iceRepository.
	repo ifNil: [ ^ '(kein Repository)' ].
	^ repo head isBranch
		ifTrue: [ repo branchName ]
		ifFalse: [ 'losgelöst (detached HEAD)' ]
]

{ #category : 'safety' }
GftUpdater class >> needsBranchDecision: aProject [
	"True if the repository is not on its tracked branch (a different branch, or detached
	HEAD) -- Graft can still proceed (see switchToUpdateBranch:for:), but the GUI should ask
	first rather than silently committing onto some unrelated branch."
	| repo |
	repo := aProject iceRepository.
	repo ifNil: [ ^ false ].
	repo head isBranch ifFalse: [ ^ true ].
	^ repo branchName ~= aProject trackedRef
]

{ #category : 'safety' }
GftUpdater class >> switchToUpdateBranch: aBranchName for: aProject [
	"Creates (from the repositorys current HEAD, keeping any working-copy state as-is) or,
	if it already exists locally, just switches to aBranchName. Used after the GUI has asked
	and Norbert confirmed putting a dependency-bump update on its own branch rather than
	whatever was checked out (see needsBranchDecision:)."
	| repo |
	repo := aProject iceRepository.
	(repo hasLocalBranchNamed: aBranchName)
		ifTrue: [ repo switchToBranchNamed: aBranchName ]
		ifFalse: [ repo createBranch: aBranchName ]
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
