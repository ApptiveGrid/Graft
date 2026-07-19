Class {
	#name : 'GftBumpPlanTest',
	#superclass : 'TestCase',
	#instVars : [
		'graph'
	],
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'running' }
GftBumpPlanTest >> setUp [
	super setUp.
	graph := GftDependencyGraph build
]

{ #category : 'tests' }
GftBumpPlanTest >> testCascadeFromSoilReachesApptiveCommonAtLevel1 [
	| plan step |
	plan := GftBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	step := plan concreteSteps detect: [ :s | s ownerProjectName = 'apptive-common' ].
	self assert: step levelDepth equals: 1.
	self assert: step newRef equals: 'deadbeef'
]

{ #category : 'tests' }
GftBumpPlanTest >> testCascadeFromSoilReachesConsumersAtLevel2AsPending [
	| plan pendingOwners |
	plan := GftBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	pendingOwners := plan pendingSteps collect: [ :s | s ownerProjectName ].
	self assert: (pendingOwners includes: 'apptive-base').
	self assert: (pendingOwners includes: 'apptive-account').
	self assert: (pendingOwners includes: 'apptive-scheduler').
	plan pendingSteps do: [ :s | self deny: s isConcrete ]
]

{ #category : 'tests' }
GftBumpPlanTest >> testFloatingDependentsIncludeRhizomeBranchPin [
	| plan owners |
	plan := GftBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	owners := plan floatingDependents collect: [ :r | r ownerProjectName ].
	self assert: (owners includes: 'Rhizome')
]

{ #category : 'tests' }
GftBumpPlanTest >> testTriggerProjectItselfNeverReappearsAsAStep [
	| plan |
	plan := GftBumpPlan for: 'Soil' newCommit: 'deadbeef' usingGraph: graph.
	self deny: (plan steps anySatisfy: [ :s | s ownerProjectName = 'Soil' ])
]
