Class {
	#name : 'GftBumpStep',
	#superclass : 'Object',
	#instVars : [
		'reference',
		'newRef',
		'levelDepth',
		'concrete'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'instance creation' }
GftBumpStep class >> reference: aReference newRef: aNewRefOrNil levelDepth: aLevel concrete: aBoolean [
	^ self new
		setReference: aReference newRef: aNewRefOrNil levelDepth: aLevel concrete: aBoolean;
		yourself
]

{ #category : 'testing' }
GftBumpStep >> isConcrete [
	"True for level-1 steps, where the new ref is a real, already-known commit sha.
	False for level 2+ (see RSBumpPlan class comment): those depend on a commit that would
	only be created once this step is actually applied, so they cannot be computed for real
	in a single dry-run pass."
	^ concrete
]

{ #category : 'accessing' }
GftBumpStep >> levelDepth [
	^ levelDepth
]

{ #category : 'accessing' }
GftBumpStep >> newRef [
	^ newRef
]

{ #category : 'accessing' }
GftBumpStep >> ownerProjectName [
	^ reference ownerProjectName
]

{ #category : 'printing' }
GftBumpStep >> printOn: aStream [
	aStream
		nextPutAll: 'RSBumpStep(L';
		print: levelDepth;
		nextPutAll: ' ';
		nextPutAll: reference ownerProjectName;
		nextPutAll: ' / ';
		nextPutAll: reference declaredName;
		nextPutAll: ' -> ';
		nextPutAll: (concrete ifTrue: [ newRef ] ifFalse: [ '??? (depends on unapplied step)' ]);
		nextPut: $)
]

{ #category : 'accessing' }
GftBumpStep >> reference [
	^ reference
]

{ #category : 'private' }
GftBumpStep >> setReference: aReference newRef: aNewRefOrNil levelDepth: aLevel concrete: aBoolean [
	reference := aReference.
	newRef := aNewRefOrNil.
	levelDepth := aLevel.
	concrete := aBoolean
]
