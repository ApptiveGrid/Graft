Class {
	#name : 'GftDiffFormatterTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'tests' }
GftDiffFormatterTest >> testChangeNodesLabelAdditionsCorrectlyDespiteIcebergsInvertedClassNaming [
	"Regression test for the labelFor: fix: IceAddition/IceRemoval are named from Icebergs
	internal tree-merge perspective, which turns out backwards for a plain old->new diff --
	verified against a real, known case: Soil commit 5a4cbf89..f7edb9c2 added a whole new test
	class (SoilTestGrowingRecord) and a regression test method, both of which must be labeled
	+ (present in new, absent in old), not - ."
	| nodes labelled |
	nodes := GftDiffFormatter
		changeNodesFor: (GftProject named: 'Soil')
		oldRef: '5a4cbf89f4bea0628c6e6be78a726156a56b4f33'
		newRef: 'f7edb9c26ba9db93815651f1d20f04ad66bd3b6d'.
	labelled := nodes collect: [ :n | (GftDiffFormatter labelFor: n), (GftDiffFormatter pathFor: n) ].
	self assert: (labelled includes: '+ src>>Soil-Core-Tests>>SoilTestGrowingRecord')
]

{ #category : 'tests' }
GftDiffFormatterTest >> testTextDiffForIdenticalRefsReportsNoDifference [
	| text |
	text := GftDiffFormatter
		textDiffFor: (GftProject named: 'Soil')
		oldRef: '5a4cbf89f4bea0628c6e6be78a726156a56b4f33'
		newRef: '5a4cbf89f4bea0628c6e6be78a726156a56b4f33'.
	self assert: (text includesSubstring: 'Kein Unterschied')
]

{ #category : 'tests' }
GftDiffFormatterTest >> testTextDiffForRealStaleReferenceListsChanges [
	"Live/integration-style, like the rest of this suite: finds a real currently-stale
	reference and verifies the diff between its pinned and effective-tip commit lists at
	least one changed method/class -- read-only, no mutation."
	| g refs ref text |
	g := GftDependencyGraph build.
	refs := g allReferences select: [ :r | r isStale ].
	refs isEmpty ifTrue: [ ^ self skip ].
	ref := refs first.
	text := GftDiffFormatter
		textDiffFor: ref targetProject
		oldRef: ref url ref
		newRef: (GftVersionResolver effectiveTipFor: ref targetProject).
	self assert: (text includesSubstring: ref targetProject name).
	self assert: (text includesSubstring: 'Ice')
]
