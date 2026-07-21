Class {
	#name : 'GftRepositoryUrlTest',
	#superclass : 'TestCase',
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'tests' }
GftRepositoryUrlTest >> testParseAbbreviatedCommitHashIsStillClassifiedAsCommit [
	"Regression test: git often abbreviates SHAs (commonly 7-12 chars). Found 2026-07-19 in the
	real ecosystem (BaselineOfApptiveBase>>fluxbase: pinned via the short form '90341f8') --
	this used to be misclassified as #branch, hiding it from staleness detection entirely."
	| url |
	url := GftRepositoryUrl parse: 'github://ApptiveGrid/FluxBase:90341f8/source'.
	self assert: url pinKind equals: #commit.
	self assert: url ref equals: '90341f8'
]

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

{ #category : 'tests' }
GftRepositoryUrlTest >> testParseVeryShortHexLikeStringIsNotTreatedAsCommit [
	"Refs shorter than 4 chars are below the minimum length Graft accepts as a plausible
	abbreviated SHA -- treated as a branch name instead (avoids misclassifying very short branch
	names that happen to look hex-ish, however unlikely). 4 chars and up (still all-hex) is
	accepted as an abbreviated commit, matching gits own minimum abbreviation length."
	| url |
	url := GftRepositoryUrl parse: 'github://ApptiveGrid/FluxBase:abc/source'.
	self assert: url pinKind equals: #branch.
	url := GftRepositoryUrl parse: 'github://ApptiveGrid/FluxBase:abcd/source'.
	self assert: url pinKind equals: #commit
]
