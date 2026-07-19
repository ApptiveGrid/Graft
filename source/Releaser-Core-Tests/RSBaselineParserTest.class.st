Class {
	#name : 'RSBaselineParserTest',
	#superclass : 'TestCase',
	#category : 'Releaser-Core-Tests',
	#package : 'Releaser-Core-Tests'
}

{ #category : 'tests' }
RSBaselineParserTest >> testAllKnownProjectsParseWithoutError [
	RSProject knownProjects do: [ :p |
		[ RSBaselineParser referencesFor: p ]
			on: Error
			do: [ :e | self fail: 'parsing ', p name, ' raised: ', e messageText ] ]
]

{ #category : 'tests' }
RSBaselineParserTest >> testApptiveBaseReferencesFluxBaseAsCommitPin [
	| refs ref |
	refs := RSBaselineParser referencesFor: (RSProject named: 'apptive-base').
	ref := refs detect: [ :r | r declaredName = 'FluxBase' ].
	self assert: ref pinKind equals: #commit.
	self deny: ref isExternal.
	self assert: ref targetProject name equals: 'FluxBase'
]

{ #category : 'tests' }
RSBaselineParserTest >> testApptiveBaseReferencesNeoCSVAsExternalLeaf [
	| refs ref |
	refs := RSBaselineParser referencesFor: (RSProject named: 'apptive-base').
	ref := refs detect: [ :r | r declaredName = 'NeoCSV' ].
	self assert: ref isExternal
]

{ #category : 'tests' }
RSBaselineParserTest >> testApptiveCommonPinIsLocatedInHelperMethodNotTheDeclaringMethod [
	"Regression test for the commonCommitHash indirection pattern, see Releaser doc."
	| refs ref |
	refs := RSBaselineParser referencesFor: (RSProject named: 'apptive-base').
	ref := refs detect: [ :r | r declaredName = 'ApptiveCommon' ].
	self assert: ref pinKind equals: #commit.
	self assert: ref url owner equals: '2denker'.
	self assert: ref url repoName equals: 'apptive-common'
]

{ #category : 'tests' }
RSBaselineParserTest >> testHOPReferencesJSONSchemaAsKnownProject [
	| refs ref |
	refs := RSBaselineParser referencesFor: (RSProject named: 'HOP').
	ref := refs detect: [ :r | r declaredName = 'JSONSchema' ].
	self deny: ref isExternal.
	self assert: ref targetProject name equals: 'JSONSchema'
]
