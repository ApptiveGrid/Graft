Class {
	#name : 'GftUpdaterTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

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
GftUpdaterTest >> testBlockersFlagModifiedRepo [
	GftProject knownProjects do: [ :p |
		| repo |
		repo := p iceRepository.
		(repo notNil and: [ repo isModified ]) ifTrue: [
			self assert: (GftUpdater blockersForUpdating: p) isNotEmpty ] ]
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
