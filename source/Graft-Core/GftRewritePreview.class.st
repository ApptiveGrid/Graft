Class {
	#name : 'GftRewritePreview',
	#superclass : 'Object',
	#instVars : [
		'reference',
		'oldRef',
		'newRef',
		'matches'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'instance creation' }
GftRewritePreview class >> reference: aReference oldRef: anOldRef newRef: aNewRef matches: aMatchesCollection [
	^ self new
		setReference: aReference oldRef: anOldRef newRef: aNewRef matches: aMatchesCollection;
		yourself
]

{ #category : 'printing' }
GftRewritePreview >> diffText [
	| stream |
	stream := String new writeStream.
	stream nextPutAll: '--- ', reference ownerProjectName, ' / ', (reference targetProject ifNil: [reference declaredName] ifNotNil: [:t | t name]), ' ---'; cr.
	self status = #ok
		ifTrue: [
			stream
				nextPutAll: 'method: ', self selector; cr;
				nextPutAll: '- old ref: ', oldRef; cr;
				nextPutAll: '+ new ref: ', newRef; cr; cr;
				nextPutAll: '--- proposed new source ---'; cr;
				nextPutAll: self newSource ]
		ifFalse: [
			stream nextPutAll: 'status: ', self status printString, ' -- ', matches size printString, ' method(s) mention the old ref ', oldRef printString ].
	^ stream contents
]

{ #category : 'accessing' }
GftRewritePreview >> matches [
	"Association selector -> proposed new method source, one per instance method of the
	owning BaselineOf class whose source contains the old ref literally."
	^ matches
]

{ #category : 'accessing' }
GftRewritePreview >> newRef [
	^ newRef
]

{ #category : 'accessing' }
GftRewritePreview >> newSource [
	self status = #ok ifFalse: [ ^ self error: 'Only available when status = #ok (exactly one match); status is ', self status ].
	^ matches first value
]

{ #category : 'accessing' }
GftRewritePreview >> oldRef [
	^ oldRef
]

{ #category : 'accessing' }
GftRewritePreview >> oldSource [
	self status = #ok ifFalse: [ ^ self error: 'Only available when status = #ok (exactly one match); status is ', self status ].
	^ (GftProject named: reference ownerProjectName) baselineClass sourceCodeAt: self selector
]

{ #category : 'accessing' }
GftRewritePreview >> reference [
	^ reference
]

{ #category : 'accessing' }
GftRewritePreview >> selector [
	self status = #ok ifFalse: [ ^ self error: 'Only available when status = #ok (exactly one match); status is ', self status ].
	^ matches first key
]

{ #category : 'private' }
GftRewritePreview >> setReference: aReference oldRef: anOldRef newRef: aNewRef matches: aMatchesCollection [
	reference := aReference.
	oldRef := anOldRef.
	newRef := aNewRef.
	matches := aMatchesCollection
]

{ #category : 'testing' }
GftRewritePreview >> status [
	"#ok: exactly one method needs editing (the common, expected case).
	#ambiguous: more than one method mentions the old ref -- Graft cannot safely guess
	which is the real declaration site, needs a human to pick.
	#notFound: no method mentions the old ref as a literal -- likely assembled in a way
	this simple text-based rewriter cannot locate; needs a manual edit."
	matches size = 1 ifTrue: [ ^ #ok ].
	matches isEmpty ifTrue: [ ^ #notFound ].
	^ #ambiguous
]
