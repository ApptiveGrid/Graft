Class {
	#name : 'RSBumpPlanTest',
	#superclass : 'TestCase',
	#instVars : [
		'graph'
	],
	#category : 'Releaser-Core-Tests',
	#package : 'Releaser-Core-Tests'
}

{ #category : 'running' }
RSBumpPlanTest >> setUp [
	super setUp.
	graph := RSDependencyGraph build
]

{ #category : 'tests' }
RSBumpPlanTest >> testCascadeFromSoilReachesApptiveCommonAtLevel1 [
	| plan step |
	plan := RSBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	step := plan concreteSteps detect: [ :s | s ownerProjectName = 'apptive-common' ].
	self assert: step levelDepth equals: 1.
	self assert: step newRef equals: 'deadbeef'
]

{ #category : 'tests' }
RSBumpPlanTest >> testCascadeFromSoilReachesConsumersAtLevel2AsPending [
	| plan pendingOwners |
	plan := RSBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	pendingOwners := plan pendingSteps collect: [ :s | s ownerProjectName ].
	self assert: (pendingOwners includes: 'apptive-base').
	self assert: (pendingOwners includes: 'apptive-account').
	self assert: (pendingOwners includes: 'apptive-scheduler').
	plan pendingSteps do: [ :s | self deny: s isConcrete ]
]

{ #category : 'tests' }
RSBumpPlanTest >> testFloatingDependentsIncludeRhizomeBranchPin [
	| plan owners |
	plan := RSBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	owners := plan floatingDependents collect: [ :r | r ownerProjectName ].
	self assert: (owners includes: 'Rhizome')
]

{ #category : 'tests' }
RSBumpPlanTest >> testTriggerProjectItselfNeverReappearsAsAStep [
	| plan |
	plan := RSBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	self deny: (plan steps anySatisfy: [ :s | s ownerProjectName = 'Soil' ])
]
