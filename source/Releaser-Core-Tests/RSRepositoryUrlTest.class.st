Class {
	#name : 'RSRepositoryUrlTest',
	#superclass : 'TestCase',
	#category : 'Releaser-Core-Tests',
	#package : 'Releaser-Core-Tests'
}

{ #category : 'tests' }
RSRepositoryUrlTest >> testParseBranchPinned [
	| url |
	url := RSRepositoryUrl parse: 'github://ApptiveGrid/Gossip:main/source'.
	self assert: url ref equals: 'main'.
	self assert: url pinKind equals: #branch
]

{ #category : 'tests' }
RSRepositoryUrlTest >> testParseCommitPinnedBitbucketWithConcatenation [
	"This is the shape produced once a concatenation expression like
	' ..., self commonCommitHash, ...' has already been evaluated by Metacello."
	| url |
	url := RSRepositoryUrl parse: 'bitbucket://2denker/apptive-common:1cf0e167cac1fefb43620cd8805dc1ba7beb9e5b/source'.
	self assert: url host equals: #bitbucket.
	self assert: url owner equals: '2denker'.
	self assert: url repoName equals: 'apptive-common'.
	self assert: url pinKind equals: #commit
]

{ #category : 'tests' }
RSRepositoryUrlTest >> testParseCommitPinnedGithub [
	| url |
	url := RSRepositoryUrl parse: 'github://ApptiveGrid/FluxBase:a0b4d1f6cb26f85acb0d4acda7a73405f6ccb8c7/source'.
	self assert: url host equals: #github.
	self assert: url owner equals: 'ApptiveGrid'.
	self assert: url repoName equals: 'FluxBase'.
	self assert: url ref equals: 'a0b4d1f6cb26f85acb0d4acda7a73405f6ccb8c7'.
	self assert: url path equals: 'source'.
	self assert: url pinKind equals: #commit
]

{ #category : 'tests' }
RSRepositoryUrlTest >> testParseReturnsNilForNonRepositoryString [
	self assert: (RSRepositoryUrl parse: 'not a repository url') isNil
]

{ #category : 'tests' }
RSRepositoryUrlTest >> testParseUnpinnedFloatsOnDefaultBranch [
	| url |
	url := RSRepositoryUrl parse: 'github://zweidenker/JSONSchema/source'.
	self assert: url ref isNil.
	self assert: url pinKind equals: #none.
	self assert: url path equals: 'source'
]
