Class {
	#name : 'GftBaselineParserTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'tests' }
GftBaselineParserTest >> testAbbreviatedPinIsNotMisreportedStaleWhenItIsAPrefixOfTheCurrentTip [
	"Regression test for the isStale fix (2026-07-19): apptive-bases FluxBase pin is an
	abbreviated SHA in the real ecosystem -- isStale must prefix-match against the effective
	tip, not compare for exact string equality (which would always report stale for an
	abbreviated pin, even a perfectly current one)."
	| refs ref tip |
	refs := GftBaselineParser referencesFor: (GftProject named: 'apptive-base').
	ref := refs detect: [ :r | r declaredName = 'FluxBase' ].
	self assert: ref pinKind equals: #commit.
	tip := GftVersionResolver effectiveTipFor: ref targetProject.
	tip ifNotNil: [
		(tip beginsWith: ref url ref)
			ifTrue: [ self deny: ref isStale ]
			ifFalse: [ self assert: ref isStale ] ]
]

{ #category : 'tests' }
GftBaselineParserTest >> testAllKnownProjectsParseWithoutError [
	GftProject knownProjects do: [ :p |
		[ GftBaselineParser referencesFor: p ]
			on: Error
			do: [ :e | self fail: 'parsing ', p name, ' raised: ', e messageText ] ]
]

{ #category : 'tests' }
GftBaselineParserTest >> testApptiveBaseReferencesFluxBaseAsCommitPin [
	| refs ref |
	refs := GftBaselineParser referencesFor: (GftProject named: 'apptive-base').
	ref := refs detect: [ :r | r declaredName = 'FluxBase' ].
	self assert: ref pinKind equals: #commit.
	self deny: ref isExternal.
	self assert: ref targetProject name equals: 'FluxBase'
]

{ #category : 'tests' }
GftBaselineParserTest >> testApptiveBaseReferencesNeoCSVAsExternalLeaf [
	| refs ref |
	refs := GftBaselineParser referencesFor: (GftProject named: 'apptive-base').
	ref := refs detect: [ :r | r declaredName = 'NeoCSV' ].
	self assert: ref isExternal
]

{ #category : 'tests' }
GftBaselineParserTest >> testApptiveCommonPinIsLocatedInHelperMethodNotTheDeclaringMethod [
	"Regression test for the commonCommitHash indirection pattern, see Graft doc."
	| refs ref |
	refs := GftBaselineParser referencesFor: (GftProject named: 'apptive-base').
	ref := refs detect: [ :r | r declaredName = 'ApptiveCommon' ].
	self assert: ref pinKind equals: #commit.
	self assert: ref url owner equals: '2denker'.
	self assert: ref url repoName equals: 'apptive-common'
]

{ #category : 'tests' }
GftBaselineParserTest >> testHOPReferencesJSONSchemaAsKnownProject [
	| refs ref |
	refs := GftBaselineParser referencesFor: (GftProject named: 'HOP').
	ref := refs detect: [ :r | r declaredName = 'JSONSchema' ].
	self deny: ref isExternal.
	self assert: ref targetProject name equals: 'JSONSchema'
]
