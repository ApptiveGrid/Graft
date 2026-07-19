Class {
	#name : 'RSDependencyGraphTest',
	#superclass : 'TestCase',
	#instVars : [
		'graph'
	],
	#category : 'Releaser-Core-Tests',
	#package : 'Releaser-Core-Tests'
}

{ #category : 'running' }
RSDependencyGraphTest >> setUp [
	super setUp.
	graph := RSDependencyGraph build
]

{ #category : 'tests' }
RSDependencyGraphTest >> testDependentsOfApptiveCommonIncludesAllThreeConsumers [
	| names |
	names := (graph dependentsOf: 'apptive-common') collect: [ :r | r ownerProjectName ].
	self assert: (names includes: 'apptive-base').
	self assert: (names includes: 'apptive-account').
	self assert: (names includes: 'apptive-scheduler')
]

{ #category : 'tests' }
RSDependencyGraphTest >> testDependentsOfSoilIncludesApptiveCommonAsCommitPin [
	| dependents ref |
	dependents := graph dependentsOf: 'Soil'.
	ref := dependents detect: [ :r | r ownerProjectName = 'apptive-common' ].
	self assert: ref pinKind equals: #commit
]

{ #category : 'tests' }
RSDependencyGraphTest >> testDependentsOfSoilIncludesRhizomeAsBranchPin [
	| dependents ref |
	dependents := graph dependentsOf: 'Soil'.
	ref := dependents detect: [ :r | r ownerProjectName = 'Rhizome' ].
	self assert: ref pinKind equals: #branch
]

{ #category : 'tests' }
RSDependencyGraphTest >> testEveryReferenceIsEitherExternalOrResolvesToAKnownProject [
	graph allReferences do: [ :r |
		r isExternal
			ifFalse: [ self assert: r targetProject notNil ] ]
]
