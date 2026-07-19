Class {
	#name : 'GftDependencyGraphTest',
	#superclass : 'TestCase',
	#instVars : [
		'graph'
	],
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'running' }
GftDependencyGraphTest >> setUp [
	super setUp.
	graph := GftDependencyGraph build
]

{ #category : 'tests' }
GftDependencyGraphTest >> testDependentsOfApptiveCommonIncludesAllThreeConsumers [
	| names |
	names := (graph dependentsOf: 'apptive-common') collect: [ :r | r ownerProjectName ].
	self assert: (names includes: 'apptive-base').
	self assert: (names includes: 'apptive-account').
	self assert: (names includes: 'apptive-scheduler')
]

{ #category : 'tests' }
GftDependencyGraphTest >> testDependentsOfSoilIncludesApptiveCommonAsCommitPin [
	| dependents ref |
	dependents := graph dependentsOf: 'Soil'.
	ref := dependents detect: [ :r | r ownerProjectName = 'apptive-common' ].
	self assert: ref pinKind equals: #commit
]

{ #category : 'tests' }
GftDependencyGraphTest >> testDependentsOfSoilIncludesRhizomeAsBranchPin [
	| dependents ref |
	dependents := graph dependentsOf: 'Soil'.
	ref := dependents detect: [ :r | r ownerProjectName = 'Rhizome' ].
	self assert: ref pinKind equals: #branch
]

{ #category : 'tests' }
GftDependencyGraphTest >> testEveryReferenceIsEitherExternalOrResolvesToAKnownProject [
	graph allReferences do: [ :r |
		r isExternal
			ifFalse: [ self assert: r targetProject notNil ] ]
]
