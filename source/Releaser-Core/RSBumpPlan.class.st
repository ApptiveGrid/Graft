Class {
	#name : 'RSBumpPlan',
	#superclass : 'Object',
	#instVars : [
		'triggerProjectName',
		'newCommit',
		'graph',
		'steps',
		'floatingDependents'
	],
	#category : 'Releaser-Core',
	#package : 'Releaser-Core'
}

{ #category : 'instance creation' }
RSBumpPlan class >> for: aProjectName newCommit: aCommitSha usingGraph: aGraph [
	"Computes the bump cascade triggered by aProjectName getting a new commit aCommitSha.
	Level 1 (direct commit-pinned dependents of aProjectName) is concrete: we know exactly
	which BaselineOf reference needs to point at aCommitSha. Level 2+ is necessarily only a
	preview of the cascade's shape (which projects would need a follow-up bump next) -- their
	own new commit does not exist yet because nothing gets applied automatically in v1 (Norbert
	decided 2026-07-19: preview/diff only). Re-run Releaser against the real new commit once a
	level-1 step has actually been applied to compute the next level for real."
	^ self new
		setTriggerProjectName: aProjectName newCommit: aCommitSha graph: aGraph;
		build;
		yourself
]

{ #category : 'building' }
RSBumpPlan >> build [
	| visited frontierNames levelDepth |
	visited := Set new.
	visited add: triggerProjectName.
	frontierNames := OrderedCollection new.
	(graph dependentsOf: triggerProjectName) do: [ :ref |
		ref pinKind = #commit
			ifTrue: [
				steps add: (RSBumpStep reference: ref newRef: newCommit levelDepth: 1 concrete: true).
				frontierNames add: ref ownerProjectName ]
			ifFalse: [ floatingDependents add: ref ] ].
	levelDepth := 2.
	[ frontierNames isEmpty ] whileFalse: [
		| nextFrontier |
		nextFrontier := OrderedCollection new.
		frontierNames asSet do: [ :projName |
			(visited includes: projName) ifFalse: [
				visited add: projName.
				(graph dependentsOf: projName) do: [ :ref |
					ref pinKind = #commit
						ifTrue: [
							steps add: (RSBumpStep reference: ref newRef: nil levelDepth: levelDepth concrete: false).
							nextFrontier add: ref ownerProjectName ]
						ifFalse: [ floatingDependents add: ref ] ] ] ].
		frontierNames := nextFrontier.
		levelDepth := levelDepth + 1 ]
]

{ #category : 'accessing' }
RSBumpPlan >> concreteSteps [
	^ steps select: [ :s | s isConcrete ]
]

{ #category : 'accessing' }
RSBumpPlan >> floatingDependents [
	"Direct or transitive dependents that reference the cascade via a branch-pinned or
	unpinned dependency -- these float automatically and need no BaselineOf edit, but are
	listed for visibility."
	^ floatingDependents
]

{ #category : 'testing' }
RSBumpPlan >> isEmpty [
	^ steps isEmpty and: [ floatingDependents isEmpty ]
]

{ #category : 'accessing' }
RSBumpPlan >> maxLevelDepth [
	steps ifEmpty: [ ^ 0 ].
	^ (steps collect: [ :s | s levelDepth ]) max
]

{ #category : 'accessing' }
RSBumpPlan >> newCommit [
	^ newCommit
]

{ #category : 'accessing' }
RSBumpPlan >> pendingSteps [
	^ steps reject: [ :s | s isConcrete ]
]

{ #category : 'private' }
RSBumpPlan >> setTriggerProjectName: aProjectName newCommit: aCommitSha graph: aGraph [
	triggerProjectName := aProjectName.
	newCommit := aCommitSha.
	graph := aGraph.
	steps := OrderedCollection new.
	floatingDependents := OrderedCollection new
]

{ #category : 'accessing' }
RSBumpPlan >> steps [
	^ steps
]

{ #category : 'accessing' }
RSBumpPlan >> triggerProjectName [
	^ triggerProjectName
]
