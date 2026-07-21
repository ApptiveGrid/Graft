Class {
	#name : 'GftDependencyReference',
	#superclass : 'Object',
	#instVars : [
		'ownerProjectName',
		'declaredName',
		'url'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'instance creation' }
GftDependencyReference class >> ownerProjectName: anOwnerName declaredName: aDeclaredName url: aUrl [
	^ self new
		setOwnerProjectName: anOwnerName declaredName: aDeclaredName url: aUrl;
		yourself
]

{ #category : 'accessing' }
GftDependencyReference >> declaredName [
	"The Metacello-internal project name used inside the owning BaselineOf, e.g. 'FluxBase'.
	Not necessarily identical to the target's git repository name (see #url)."
	^ declaredName
]

{ #category : 'testing' }
GftDependencyReference >> isExternal [
	^ self targetProject isNil
]

{ #category : 'testing' }
GftDependencyReference >> isStale [
	"True if this is a commit-pinned reference whose pinned commit is behind the
	target projects effective tip (local trackedRef branch if checked out there, else the
	remote-tracked tip -- see GftVersionResolver>>effectiveTipFor:). The pinned ref may be a
	full 40-char SHA or an abbreviated prefix of one (e.g. gits own default 7-char form) --
	compares via prefix match, not exact equality, so an abbreviated-but-current pin is not
	misreported as stale. Answers false for non-commit pins and for references Graft cannot
	resolve a live tip for."
	| target latest pinnedRef |
	self pinKind = #commit ifFalse: [ ^ false ].
	target := self targetProject ifNil: [ ^ false ].
	latest := GftVersionResolver effectiveTipFor: target.
	latest ifNil: [ ^ false ].
	pinnedRef := url ref.
	^ (latest beginsWith: pinnedRef) not
]

{ #category : 'accessing' }
GftDependencyReference >> ownerProjectName [
	"Name of the RSProject whose BaselineOf declares this dependency."
	^ ownerProjectName
]

{ #category : 'accessing' }
GftDependencyReference >> pinKind [
	^ url pinKind
]

{ #category : 'printing' }
GftDependencyReference >> printOn: aStream [
	aStream
		nextPutAll: 'RSDependencyReference(';
		nextPutAll: ownerProjectName;
		nextPutAll: ' -> ';
		nextPutAll: declaredName;
		nextPutAll: ' [';
		nextPutAll: self pinKind;
		nextPutAll: '])'
]

{ #category : 'private' }
GftDependencyReference >> setOwnerProjectName: anOwnerName declaredName: aDeclaredName url: aUrl [
	ownerProjectName := anOwnerName.
	declaredName := aDeclaredName.
	url := aUrl
]

{ #category : 'accessing' }
GftDependencyReference >> targetProject [
	"Resolves to the known RSProject this reference points at, or nil if it points
	outside the tracked ApptiveGrid-owned scope (a third-party/external leaf)."
	^ GftProject projectForOwner: url owner repo: url repoName
]

{ #category : 'accessing' }
GftDependencyReference >> url [
	^ url
]
