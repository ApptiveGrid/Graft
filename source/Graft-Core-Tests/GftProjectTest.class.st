Class {
	#name : 'GftProjectTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'tests' }
GftProjectTest >> testAllKnownProjectsResolveToALoadedBaselineClass [
	GftProject knownProjects do: [ :p |
		self assert: p baselineClass notNil description: p baselineClassName, ' is not a loaded class (', p name, ')' ]
]

{ #category : 'tests' }
GftProjectTest >> testAllKnownProjectsResolveToARealIceRepository [
	GftProject knownProjects do: [ :p |
		self assert: p iceRepository notNil description: 'no Iceberg repository registered for ', p name ]
]

{ #category : 'tests' }
GftProjectTest >> testNamedLooksUpByExactName [
	self assert: (GftProject named: 'FluxBase') name equals: 'FluxBase'.
	self assert: (GftProject named: 'does-not-exist') isNil
]

{ #category : 'tests' }
GftProjectTest >> testProjectForOwnerRepoAnswersNilForThirdPartyRepo [
	self assert: (GftProject projectForOwner: 'svenvc' repo: 'NeoCSV') isNil
]

{ #category : 'tests' }
GftProjectTest >> testProjectForOwnerRepoResolvesKnownProject [
	| p |
	p := GftProject projectForOwner: 'ApptiveGrid' repo: 'FluxBase'.
	self assert: p notNil.
	self assert: p name equals: 'FluxBase'
]
