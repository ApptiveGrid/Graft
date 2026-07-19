Class {
	#name : 'RSVersionResolver',
	#superclass : 'Object',
	#category : 'Releaser-Core',
	#package : 'Releaser-Core'
}

{ #category : 'fetching' }
RSVersionResolver class >> fetch: aProject [
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
RSVersionResolver class >> fetchAll: aCollectionOfProjects [
	"Fetches every project in the collection, tolerating individual failures.
	Answers a Dictionary from project name to a Boolean success flag."
	| results |
	results := Dictionary new.
	aCollectionOfProjects do: [ :project | results at: project name put: (self fetch: project) ].
	^ results
]

{ #category : 'querying' }
RSVersionResolver class >> latestCommitFor: aProject [
	^ self latestCommitFor: aProject ifUnknown: [ nil ]
]

{ #category : 'querying' }
RSVersionResolver class >> latestCommitFor: aProject ifUnknown: aBlock [
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
