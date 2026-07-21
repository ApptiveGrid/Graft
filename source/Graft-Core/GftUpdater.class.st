Class {
	#name : 'GftUpdater',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'safety' }
GftUpdater class >> blockersForUpdating: aProject [
	^ self blockersForUpdating: aProject ignoringUnrelatedChanges: false
]

{ #category : 'safety' }
GftUpdater class >> blockersForUpdating: aProject ignoringUnrelatedChanges: shouldIgnore [
	"Hard safety preconditions that must hold before Graft touches aProjects repository at
	all: it must have no pre-existing uncommitted changes UNRELATED to its own BaselineOf
	package -- UNLESS shouldIgnore is true, meaning the GUI already asked and Norbert
	confirmed committing alongside that other WIP anyway (see GftPresenter>>
	offerIgnoreUnrelatedChangesFor:, added 2026-07-21: he sometimes wants to bundle a
	dependency-bump commit together with other in-progress work he already has sitting in the
	same repo, optionally on a fresh branch via offerBranchSwitchFor: first, rather than being
	refused outright). Several of the real repos in this ecosystem routinely have unrelated
	local edits in progress (verified 2026-07-19) -- shouldIgnore defaults to false everywhere
	except that one explicit, interactive path, so Graft never bundles unrelated WIP into a
	commit by accident.

	Deliberately does NOT block just because the repository is modified at all: Graft's own
	previous change-only edit (commit checkbox off, see Graft decisions) leaves the BaselineOf
	package dirty on purpose, so a second single-pin update on the same project can build on it.

	Being on the wrong branch (or detached HEAD) is not a hard blocker here either -- see
	#needsBranchDecision:/#switchToUpdateBranch:for:."
	| repo blockers otherModifiedPackages |
	blockers := OrderedCollection new.
	repo := aProject iceRepository.
	repo ifNil: [ blockers add: 'Kein Iceberg-Repository registriert.'. ^ blockers ].
	shouldIgnore ifFalse: [
		otherModifiedPackages := self unrelatedModifiedPackagesFor: aProject.
		otherModifiedPackages isEmpty ifFalse: [
			blockers add: 'Repository hat bereits unabhängige, nicht committete Änderungen in: ',
				((otherModifiedPackages collect: [ :p | p name ]) fold: [ :a :b | a, ', ', b ]),
				' -- Graft fasst das nicht an.' ] ].
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

{ #category : 'safety' }
GftUpdater class >> unrelatedModifiedPackagesFor: aProject [
	"Modified packages in aProjects repository other than its own BaselineOf package -- the
	pre-existing, Graft-unrelated WIP that #blockersForUpdating: normally refuses to touch.
	Answers an empty collection if there is no repository or nothing unrelated is dirty."
	| repo baselinePackageName |
	repo := aProject iceRepository.
	repo ifNil: [ ^ #() ].
	baselinePackageName := aProject baselineClassName.
	^ repo modifiedPackages reject: [ :pkg | pkg name = baselinePackageName ]
]

{ #category : 'updating' }
GftUpdater class >> updateAll [
	^ self updateProjects: (GftProject knownProjects collect: [ :p | p name ]) commit: true
]

{ #category : 'updating' }
GftUpdater class >> updateProject: aProject references: refs commit: shouldCommit [
	^ self updateProject: aProject references: refs commit: shouldCommit ignoringUnrelatedChanges: false
]

{ #category : 'updating' }
GftUpdater class >> updateProject: aProject references: refs commit: shouldCommit ignoringUnrelatedChanges: shouldIgnore [
	"Like #updateProject:usingGraph:commit:, but applies exactly the given references (a
	subset of aProjects stale outgoing refs, e.g. hand-picked by the user in the GUI) instead
	of automatically bundling every currently-stale reference of aProject into one commit.
	shouldIgnore: see blockersForUpdating:ignoringUnrelatedChanges: -- if true, a commit here
	will bundle in whatever other unrelated changes are already sitting in the repo, because
	the GUI already asked and Norbert confirmed that."
	| blockers applied skipped |
	blockers := self blockersForUpdating: aProject ignoringUnrelatedChanges: shouldIgnore.
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
	^ self updateReferences: aReferenceCollection commit: shouldCommit ignoringUnrelatedChanges: false
]

{ #category : 'updating' }
GftUpdater class >> updateReferences: aReferenceCollection commit: shouldCommit ignoringUnrelatedChanges: shouldIgnore [
	"Applies exactly the given references (which may belong to different owner projects),
	one commit per owner project (if shouldCommit), containing only the selected references --
	never the rest of that project's stale pins, unless shouldIgnore is true (see
	blockersForUpdating:ignoringUnrelatedChanges:), in which case whatever else is already
	dirty in a given project gets bundled into that projects commit too. Does not cascade
	rounds -- each reference is applied exactly once, as picked."
	| byProject results |
	byProject := Dictionary new.
	aReferenceCollection do: [ :ref |
		(byProject at: ref ownerProjectName ifAbsentPut: [ OrderedCollection new ]) add: ref ].
	results := OrderedCollection new.
	byProject keysAndValuesDo: [ :projectName :refs |
		results add: (self
			updateProject: (GftProject named: projectName)
			references: refs
			commit: shouldCommit
			ignoringUnrelatedChanges: shouldIgnore) ].
	^ results
]
