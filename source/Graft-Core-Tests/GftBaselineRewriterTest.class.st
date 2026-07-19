Class {
	#name : 'GftBaselineRewriterTest',
	#superclass : 'TestCase',
	#instVars : [
		'graph'
	],
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'running' }
GftBaselineRewriterTest >> setUp [
	super setUp.
	graph := GftDependencyGraph build
]

{ #category : 'tests' }
GftBaselineRewriterTest >> testPreviewForDirectLiteralPinLocatesDeclaringMethod [
	| plan step preview |
	plan := GftBumpPlan for: 'FluxBase' newCommit: 'cafef00d' usingGraph: graph.
	step := plan concreteSteps detect: [ :s | s ownerProjectName = 'apptive-base' ].
	preview := GftBaselineRewriter previewFor: step.
	self assert: preview status equals: #ok.
	self assert: preview selector equals: #fluxbase:.
	self assert: (preview newSource includesSubstring: 'cafef00d').
	self deny: (preview newSource includesSubstring: preview oldRef)
]

{ #category : 'tests' }
GftBaselineRewriterTest >> testPreviewForHelperMethodIndirectionLocatesHelperNotDeclaringMethod [
	| plan step preview |
	plan := GftBumpPlan for: 'apptive-common' newCommit: 'cafef00d' usingGraph: graph.
	step := plan concreteSteps detect: [ :s | s ownerProjectName = 'apptive-base' ].
	preview := GftBaselineRewriter previewFor: step.
	self assert: preview status equals: #ok.
	self assert: preview selector equals: #commonCommitHash.
	self assert: (preview newSource includesSubstring: 'cafef00d')
]

{ #category : 'tests' }
GftBaselineRewriterTest >> testPreviewRefusesPendingSteps [
	| plan step |
	plan := GftBumpPlan for: 'Soil' newCommit: 'cafef00d' usingGraph: graph.
	step := plan pendingSteps first.
	self should: [ GftBaselineRewriter previewFor: step ] raise: Error
]
