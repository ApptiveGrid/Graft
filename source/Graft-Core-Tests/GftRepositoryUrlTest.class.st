Class {
	#name : 'GftRepositoryUrlTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'tests' }
GftRepositoryUrlTest >> testParseBranchPinned [
	| url |
	url := GftRepositoryUrl parse: 'github://ApptiveGrid/Gossip:main/source'.
	self assert: url ref equals: 'main'.
	self assert: url pinKind equals: #branch
]

{ #category : 'tests' }
GftRepositoryUrlTest >> testParseCommitPinnedBitbucketWithConcatenation [
	"This is the shape produced once a concatenation expression like
	' ..., self commonCommitHash, ...' has already been evaluated by Metacello."
	| url |
	url := GftRepositoryUrl parse: 'bitbucket://2denker/apptive-common:1cf0e167cac1fefb43620cd8805dc1ba7beb9e5b/source'.
	self assert: url host equals: #bitbucket.
	self assert: url owner equals: '2denker'.
	self assert: url repoName equals: 'apptive-common'.
	self assert: url pinKind equals: #commit
]

{ #category : 'tests' }
GftRepositoryUrlTest >> testParseCommitPinnedGithub [
	| url |
	url := GftRepositoryUrl parse: 'github://ApptiveGrid/FluxBase:a0b4d1f6cb26f85acb0d4acda7a73405f6ccb8c7/source'.
	self assert: url host equals: #github.
	self assert: url owner equals: 'ApptiveGrid'.
	self assert: url repoName equals: 'FluxBase'.
	self assert: url ref equals: 'a0b4d1f6cb26f85acb0d4acda7a73405f6ccb8c7'.
	self assert: url path equals: 'source'.
	self assert: url pinKind equals: #commit
]

{ #category : 'tests' }
GftRepositoryUrlTest >> testParseReturnsNilForNonRepositoryString [
	self assert: (GftRepositoryUrl parse: 'not a repository url') isNil
]

{ #category : 'tests' }
GftRepositoryUrlTest >> testParseUnpinnedFloatsOnDefaultBranch [
	| url |
	url := GftRepositoryUrl parse: 'github://zweidenker/JSONSchema/source'.
	self assert: url ref isNil.
	self assert: url pinKind equals: #none.
	self assert: url path equals: 'source'
]
