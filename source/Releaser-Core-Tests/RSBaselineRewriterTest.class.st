Class {
	#name : 'RSBaselineRewriterTest',
	#superclass : 'TestCase',
	#instVars : [
		'graph'
	],
	#category : 'Releaser-Core-Tests',
	#package : 'Releaser-Core-Tests'
}

{ #category : 'running' }
RSBaselineRewriterTest >> setUp [
	super setUp.
	graph := RSDependencyGraph build
]

{ #category : 'tests' }
RSBaselineRewriterTest >> testPreviewForDirectLiteralPinLocatesDeclaringMethod [
	| plan step preview |
	plan := RSBumpPlan for: 'FluxBase' newCommit: 'cafef00d' usingGraph: graph.
	step := plan concreteSteps detect: [ :s | s ownerProjectName = 'apptive-base' ].
	preview := RSBaselineRewriter previewFor: step.
	self assert: preview status equals: #ok.
	self assert: preview selector equals: #fluxbase:.
	self assert: (preview newSource includesSubstring: 'cafef00d').
	self deny: (preview newSource includesSubstring: preview oldRef)
]

{ #category : 'tests' }
RSBaselineRewriterTest >> testPreviewForHelperMethodIndirectionLocatesHelperNotDeclaringMethod [
	| plan step preview |
	plan := RSBumpPlan for: 'apptive-common' newCommit: 'cafef00d' usingGraph: graph.
	step := plan concreteSteps detect: [ :s | s ownerProjectName = 'apptive-base' ].
	preview := RSBaselineRewriter previewFor: step.
	self assert: preview status equals: #ok.
	self assert: preview selector equals: #commonCommitHash.
	self assert: (preview newSource includesSubstring: 'cafef00d')
]

{ #category : 'tests' }
RSBaselineRewriterTest >> testPreviewRefusesPendingSteps [
	| plan step |
	plan := RSBumpPlan for: 'Soil' newCommit: 'cafef00d' usingGraph: graph.
	step := plan pendingSteps first.
	self should: [ RSBaselineRewriter previewFor: step ] raise: Error
]
