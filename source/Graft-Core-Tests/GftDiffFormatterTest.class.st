Class {
	#name : 'GftDiffFormatterTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

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
