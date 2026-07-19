Class {
	#name : 'GftRepositoryUrl',
	#superclass : 'Object',
	#instVars : [
		'raw',
		'scheme',
		'owner',
		'repoName',
		'ref',
		'path'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'parsing' }
GftRepositoryUrl class >> parse: aString [
	"Parses Metacello repository description strings of the shape
	<scheme>://<owner>/<repo>[:<ref>]/<path>, e.g.
	'github://ApptiveGrid/FluxBase:a0b4d1f6.../source' or
	'github://zweidenker/JSONSchema/source' (no ref, floats on default branch).
	Answers nil if aString does not look like a Metacello repository description at all."
	| schemeSplit remainder ownerAndRest firstSlash owner repoAndRef path colonIndex repo ref |
	schemeSplit := aString indexOf: $:.
	(schemeSplit = 0 or: [ (aString copyFrom: schemeSplit to: (schemeSplit + 2 min: aString size)) ~= '://' ])
		ifTrue: [ ^ nil ].
	remainder := aString copyFrom: schemeSplit + 3 to: aString size.
	firstSlash := remainder indexOf: $/.
	firstSlash = 0 ifTrue: [ ^ nil ].
	owner := remainder copyFrom: 1 to: firstSlash - 1.
	ownerAndRest := remainder copyFrom: firstSlash + 1 to: remainder size.
	firstSlash := ownerAndRest indexOf: $/.
	firstSlash = 0
		ifTrue: [ repoAndRef := ownerAndRest. path := '' ]
		ifFalse: [
			repoAndRef := ownerAndRest copyFrom: 1 to: firstSlash - 1.
			path := ownerAndRest copyFrom: firstSlash + 1 to: ownerAndRest size ].
	colonIndex := repoAndRef indexOf: $:.
	colonIndex = 0
		ifTrue: [ repo := repoAndRef. ref := nil ]
		ifFalse: [
			repo := repoAndRef copyFrom: 1 to: colonIndex - 1.
			ref := repoAndRef copyFrom: colonIndex + 1 to: repoAndRef size ].
	^ self new
		setRaw: aString scheme: (aString copyFrom: 1 to: schemeSplit - 1) owner: owner repoName: repo ref: ref path: path;
		yourself
]

{ #category : 'accessing' }
GftRepositoryUrl >> host [
	"Symbolic host for the well-known schemes used in this ecosystem; nil for anything else."
	scheme = 'github' ifTrue: [ ^ #github ].
	scheme = 'bitbucket' ifTrue: [ ^ #bitbucket ].
	^ nil
]

{ #category : 'accessing' }
GftRepositoryUrl >> owner [
	^ owner
]

{ #category : 'accessing' }
GftRepositoryUrl >> path [
	^ path
]

{ #category : 'testing' }
GftRepositoryUrl >> pinKind [
	"#commit if the ref looks like a full git commit SHA (40 hex chars), #branch if some
	other ref is pinned (the dependency still floats to whatever that branch points at),
	#none if there is no ref at all (floats on the remote's default branch)."
	ref ifNil: [ ^ #none ].
	^ (ref size = 40 and: [ ref allSatisfy: [ :c | c isDigit or: [ c asLowercase between: $a and: $f ] ] ])
		ifTrue: [ #commit ]
		ifFalse: [ #branch ]
]

{ #category : 'printing' }
GftRepositoryUrl >> printOn: aStream [
	aStream nextPutAll: 'RSRepositoryUrl(', raw, ')'
]

{ #category : 'accessing' }
GftRepositoryUrl >> raw [
	^ raw
]

{ #category : 'accessing' }
GftRepositoryUrl >> ref [
	^ ref
]

{ #category : 'accessing' }
GftRepositoryUrl >> repoName [
	^ repoName
]

{ #category : 'accessing' }
GftRepositoryUrl >> scheme [
	^ scheme
]

{ #category : 'private' }
GftRepositoryUrl >> setRaw: aRaw scheme: aScheme owner: anOwner repoName: aRepo ref: aRef path: aPath [
	raw := aRaw.
	scheme := aScheme.
	owner := anOwner.
	repoName := aRepo.
	ref := aRef.
	path := aPath
]
