Class {
	#name : 'GftUpdaterTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'tests' }
GftUpdaterTest >> testBlockersDoNotFlagOwnBaselinePackageBeingModified [
	"A projects own BaselineOf package being the ONLY dirty one must NOT block by itself --
	this is what lets several sequential change-only (no commit) single-pin updates on the same
	project build on each other instead of the second one failing because the first left the
	project modified (Norbert reported exactly this 2026-07-20)."
	GftProject knownProjects do: [ :p |
		| repo otherDirty blockers |
		repo := p iceRepository.
		repo ifNotNil: [
			otherDirty := repo modifiedPackages reject: [ :pkg | pkg name = p baselineClassName ].
			otherDirty isEmpty ifTrue: [
				blockers := GftUpdater blockersForUpdating: p.
				blockers do: [ :b | self deny: (b includesSubstring: 'unabhängige') ] ] ] ]
]

{ #category : 'tests' }
GftUpdaterTest >> testBlockersFlagBranchMismatch [
	"Read-only check: whenever a known project's repo is not on its tracked branch, blockers
	must be non-empty. Deliberately does not hardcode which projects are affected -- branch
	state changes over time -- only the invariant."
	GftProject knownProjects do: [ :p |
		| repo |
		repo := p iceRepository.
		repo ifNotNil: [
			(repo head isBranch and: [ repo branchName = p trackedRef ])
				ifFalse: [ self assert: (GftUpdater blockersForUpdating: p) isNotEmpty ] ] ]
]

{ #category : 'tests' }
GftUpdaterTest >> testBlockersFlagUnrelatedModifiedPackages [
	"Being modified in some OTHER package (not the project own BaselineOf) must still block --
	this is the real safety net against bundling unrelated WIP into a Graft commit."
	GftProject knownProjects do: [ :p |
		| repo otherDirty |
		repo := p iceRepository.
		repo ifNotNil: [
			otherDirty := repo modifiedPackages reject: [ :pkg | pkg name = p baselineClassName ].
			otherDirty isEmpty ifFalse: [
				self assert: (GftUpdater blockersForUpdating: p) isNotEmpty ] ] ]
]

{ #category : 'tests' }
GftUpdaterTest >> testSummaryDistinguishesChangedFromCommitted [
	| committedResult changedOnlyResult |
	committedResult := GftUpdateResult projectName: 'x' blockers: #() applied: { 'Y' -> 'abc' } skipped: #() commitId: 'deadbeef'.
	self assert: committedResult wasCommitted.
	self assert: (committedResult summary includesSubstring: 'committet').
	changedOnlyResult := GftUpdateResult projectName: 'x' blockers: #() applied: { 'Y' -> 'abc' } skipped: #() commitId: nil.
	self deny: changedOnlyResult wasCommitted.
	self assert: changedOnlyResult wasChangedButNotCommitted.
	self assert: (changedOnlyResult summary includesSubstring: 'NICHT committet')
]

{ #category : 'tests' }
GftUpdaterTest >> testUpdateProjectCommitFalseNeverTouchesABlockedProject [
	GftProject knownProjects do: [ :p |
		| blockers result |
		blockers := GftUpdater blockersForUpdating: p.
		blockers isEmpty ifFalse: [
			result := GftUpdater updateProject: p usingGraph: GftDependencyGraph build commit: false.
			self assert: result isBlocked.
			self assert: result commitId isNil.
			self assert: result applied isEmpty ] ]
]

{ #category : 'tests' }
GftUpdaterTest >> testUpdateProjectNeverTouchesABlockedProject [
	"Guards against a regression that would silently start mutating/committing a project whose
	repository isn't safe to touch. Only exercises the actually-blocked path -- must NEVER call
	updateProject: on a project that is currently safe, since that would create a real commit as
	a side effect of running the test suite."
	GftProject knownProjects do: [ :p |
		| blockers result |
		blockers := GftUpdater blockersForUpdating: p.
		blockers isEmpty ifFalse: [
			result := GftUpdater updateProject: p usingGraph: GftDependencyGraph build.
			self assert: result isBlocked.
			self assert: result commitId isNil.
			self assert: result applied isEmpty ] ]
]

{ #category : 'tests' }
GftUpdaterTest >> testUpdateProjectsCommitFalseNeverTouchesABlockedSet [
	"Only ever passes a project name to updateProjects:commit: if it is currently blocked --
	must never create a real commit or a real code change as a side effect of this test."
	| blockedNames results |
	blockedNames := (GftProject knownProjects select: [ :p | (GftUpdater blockersForUpdating: p) isNotEmpty ]) collect: [ :p | p name ].
	blockedNames isEmpty ifFalse: [
		results := GftUpdater updateProjects: blockedNames commit: false.
		results do: [ :r | self assert: r isBlocked ] ]
]

{ #category : 'tests' }
GftUpdaterTest >> testUpdateReferencesNeverTouchesABlockedProject [
	"Only ever passes references whose owner project is currently blocked -- must never create
	a real commit or code change as a side effect of running this test."
	| blockedProject refs results |
	blockedProject := GftProject knownProjects detect: [ :p | (GftUpdater blockersForUpdating: p) isNotEmpty ] ifNone: [ nil ].
	blockedProject ifNotNil: [
		refs := GftDependencyGraph build staleOutgoingReferencesOf: blockedProject name.
		refs isEmpty ifFalse: [
			results := GftUpdater updateReferences: refs commit: false.
			results do: [ :r | self assert: r isBlocked ] ] ]
]

{ #category : 'tests' }
GftUpdaterTest >> testUpdateResultDidNothingWhenNoStaleRefs [
	| result |
	result := GftUpdateResult projectName: 'x' blockers: #().
	self deny: result isBlocked.
	self assert: result didNothing
]

{ #category : 'tests' }
GftUpdaterTest >> testUpdateResultSummaryForBlocked [
	| result |
	result := GftUpdateResult projectName: 'x' blockers: #('reason1' 'reason2').
	self assert: result isBlocked.
	self assert: (result summary includesSubstring: 'reason1')
]
