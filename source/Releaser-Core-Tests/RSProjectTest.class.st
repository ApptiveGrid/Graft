Class {
	#name : 'RSProjectTest',
	#superclass : 'TestCase',
	#category : 'Releaser-Core-Tests',
	#package : 'Releaser-Core-Tests'
}

{ #category : 'tests' }
RSProjectTest >> testAllKnownProjectsResolveToALoadedBaselineClass [
	RSProject knownProjects do: [ :p |
		self assert: p baselineClass notNil description: p baselineClassName, ' is not a loaded class (', p name, ')' ]
]

{ #category : 'tests' }
RSProjectTest >> testAllKnownProjectsResolveToARealIceRepository [
	RSProject knownProjects do: [ :p |
		self assert: p iceRepository notNil description: 'no Iceberg repository registered for ', p name ]
]

{ #category : 'tests' }
RSProjectTest >> testNamedLooksUpByExactName [
	self assert: (RSProject named: 'FluxBase') name equals: 'FluxBase'.
	self assert: (RSProject named: 'does-not-exist') isNil
]

{ #category : 'tests' }
RSProjectTest >> testProjectForOwnerRepoAnswersNilForThirdPartyRepo [
	self assert: (RSProject projectForOwner: 'svenvc' repo: 'NeoCSV') isNil
]

{ #category : 'tests' }
RSProjectTest >> testProjectForOwnerRepoResolvesKnownProject [
	| p |
	p := RSProject projectForOwner: 'ApptiveGrid' repo: 'FluxBase'.
	self assert: p notNil.
	self assert: p name equals: 'FluxBase'
]
