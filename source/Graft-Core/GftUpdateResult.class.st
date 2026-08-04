Class {
	#name : 'GftUpdateResult',
	#superclass : 'Object',
	#instVars : [
		'projectName',
		'blockers',
		'applied',
		'skipped',
		'commitId'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'instance creation' }
GftUpdateResult class >> projectName: aName blockers: someBlockers [
	^ self projectName: aName blockers: someBlockers applied: #() skipped: #() commitId: nil
]

{ #category : 'instance creation' }
GftUpdateResult class >> projectName: aName blockers: someBlockers applied: appliedAssocs skipped: skippedAssocs commitId: aCommitIdOrNil [
	^ self new
		setProjectName: aName blockers: someBlockers applied: appliedAssocs skipped: skippedAssocs commitId: aCommitIdOrNil;
		yourself
]

{ #category : 'accessing' }
GftUpdateResult >> applied [
	^ applied
]

{ #category : 'accessing' }
GftUpdateResult >> blockers [
	^ blockers
]

{ #category : 'accessing' }
GftUpdateResult >> commitId [
	^ commitId
]

{ #category : 'testing' }
GftUpdateResult >> didNothing [
	^ blockers isEmpty and: [ applied isEmpty ]
]

{ #category : 'testing' }
GftUpdateResult >> isBlocked [
	^ blockers isNotEmpty
]

{ #category : 'printing' }
GftUpdateResult >> printOn: aStream [
	aStream nextPutAll: 'GftUpdateResult(', self summary, ')'
]

{ #category : 'accessing' }
GftUpdateResult >> projectName [
	^ projectName
]

{ #category : 'private' }
GftUpdateResult >> setProjectName: aName blockers: someBlockers applied: appliedAssocs skipped: skippedAssocs commitId: aCommitIdOrNil [
	projectName := aName.
	blockers := someBlockers asOrderedCollection.
	applied := appliedAssocs asOrderedCollection.
	skipped := skippedAssocs asOrderedCollection.
	commitId := aCommitIdOrNil
]

{ #category : 'accessing' }
GftUpdateResult >> skipped [
	^ skipped
]

{ #category : 'printing' }
GftUpdateResult >> summary [
	| stream |
	stream := String new writeStream.
	stream nextPutAll: projectName.
	self isBlocked ifTrue: [
		stream nextPutAll: ': blocked'; cr.
		blockers do: [ :b | stream nextPutAll: '  - ', b; cr ].
		^ stream contents ].
	self didNothing ifTrue: [
		stream nextPutAll: ': nothing to do (no stale pins)'.
		^ stream contents ].
	applied isEmpty
		ifTrue: [ stream nextPutAll: ': no change applied'; cr ]
		ifFalse: [
			commitId
				ifNotNil: [ stream nextPutAll: ': committed (', commitId, ')'; cr ]
				ifNil: [ stream nextPutAll: ': code changed, NOT committed (repository now modified -- commit it yourself)'; cr ] ].
	applied do: [ :a | stream nextPutAll: '  - ', a key, ' -> ', a value; cr ].
	skipped do: [ :s | stream nextPutAll: '  - ', s key, ': skipped (', s value, ')'; cr ].
	^ stream contents
]

{ #category : 'testing' }
GftUpdateResult >> wasChangedButNotCommitted [
	^ applied isNotEmpty and: [ commitId isNil ]
]

{ #category : 'testing' }
GftUpdateResult >> wasCommitted [
	^ commitId notNil
]
