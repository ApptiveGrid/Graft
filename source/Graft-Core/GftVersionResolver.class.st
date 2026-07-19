Class {
	#name : 'GftVersionResolver',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'querying' }
GftVersionResolver class >> effectiveTipFor: aProject [
	"Like #latestCommitFor:ifUnknown:, but prefers the local trackedRef branch tip when the
	repository is currently checked out on it -- this reflects commits Graft itself may have just
	made (possibly not pushed yet). Falls back to the remote-tracked tip if the repository is on
	some other branch (a WIP feature branch, say) or detached, since the local HEAD isn't
	trustworthy as 'the tip of trackedRef' in that case."
	| repo |
	repo := aProject iceRepository.
	repo ifNil: [ ^ nil ].
	(repo head isBranch and: [ repo branchName = aProject trackedRef ])
		ifTrue: [ ^ repo headCommit id ].
	^ self latestCommitFor: aProject ifUnknown: [ nil ]
]

{ #category : 'fetching' }
GftVersionResolver class >> fetch: aProject [
	"Explicit, user-triggered network fetch of aProject's remote (read-only --
	updates the local git object database/remote-tracking branches, does not touch
	the working copy or any local branch). Answers true on success, false if the
	project has no registered Iceberg repository or the fetch failed."
	| repo |
	repo := aProject iceRepository.
	repo ifNil: [ ^ false ].
	^ [ repo fetch. true ] on: Error do: [ :e | false ]
]

{ #category : 'fetching' }
GftVersionResolver class >> fetchAll: aCollectionOfProjects [
	"Fetches every project in the collection, tolerating individual failures.
	Answers a Dictionary from project name to a Boolean success flag."
	| results |
	results := Dictionary new.
	aCollectionOfProjects do: [ :project | results at: project name put: (self fetch: project) ].
	^ results
]

{ #category : 'querying' }
GftVersionResolver class >> latestCommitFor: aProject [
	^ self latestCommitFor: aProject ifUnknown: [ nil ]
]

{ #category : 'querying' }
GftVersionResolver class >> latestCommitFor: aProject ifUnknown: aBlock [
	"Reads the current known tip commit id of aProject's tracked remote branch, purely
	from already-fetched local knowledge -- never triggers a network call itself, see #fetch:.
	Evaluates aBlock if the repository, remote branch, or commit cannot be resolved.
	NOTE: deliberately does not use IceRepository>>remoteBranchNamed:ifAbsent: -- empirically
	(verified 2026-07-19 against the real FluxBase checkout) it fails to find branches that
	really are present in #remoteTrackedBranches, so we search that list directly instead."
	| repo remoteBranchName branch |
	repo := aProject iceRepository.
	repo ifNil: [ ^ aBlock value ].
	remoteBranchName := 'origin/', aProject trackedRef.
	branch := repo remoteTrackedBranches detect: [ :b | b name = remoteBranchName ] ifNone: [ nil ].
	branch ifNil: [ ^ aBlock value ].
	^ branch commit id
]
