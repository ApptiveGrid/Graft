Class {
	#name : 'RSBumpStep',
	#superclass : 'Object',
	#instVars : [
		'reference',
		'newRef',
		'levelDepth',
		'concrete'
	],
	#category : 'Releaser-Core',
	#package : 'Releaser-Core'
}

{ #category : 'instance creation' }
RSBumpStep class >> reference: aReference newRef: aNewRefOrNil levelDepth: aLevel concrete: aBoolean [
	^ self new
		setReference: aReference newRef: aNewRefOrNil levelDepth: aLevel concrete: aBoolean;
		yourself
]

{ #category : 'testing' }
RSBumpStep >> isConcrete [
	"True for level-1 steps, where the new ref is a real, already-known commit sha.
	False for level 2+ (see RSBumpPlan class comment): those depend on a commit that would
	only be created once this step is actually applied, so they cannot be computed for real
	in a single dry-run pass."
	^ concrete
]

{ #category : 'accessing' }
RSBumpStep >> levelDepth [
	^ levelDepth
]

{ #category : 'accessing' }
RSBumpStep >> newRef [
	^ newRef
]

{ #category : 'accessing' }
RSBumpStep >> ownerProjectName [
	^ reference ownerProjectName
]

{ #category : 'printing' }
RSBumpStep >> printOn: aStream [
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
RSBumpStep >> reference [
	^ reference
]

{ #category : 'private' }
RSBumpStep >> setReference: aReference newRef: aNewRefOrNil levelDepth: aLevel concrete: aBoolean [
	reference := aReference.
	newRef := aNewRefOrNil.
	levelDepth := aLevel.
	concrete := aBoolean
]
