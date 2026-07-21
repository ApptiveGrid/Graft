Class {
	#name : 'GftDiffPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'changesList',
		'oldCodeText',
		'newCodeText'
	],
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'accessing' }
GftDiffPresenter class >> defaultPreferredExtent [
	^ 1000@600
]

{ #category : 'instance creation' }
GftDiffPresenter class >> openForProject: aProject oldRef: oldRef newRef: newRef [
	| nodes p |
	nodes := GftDiffFormatter changeNodesFor: aProject oldRef: oldRef newRef: newRef.
	p := self new.
	p changeNodes: nodes asOrderedCollection.
	p open.
	^ p
]

{ #category : 'accessing' }
GftDiffPresenter >> changeNodes: aCollection [
	changesList items: aCollection.
	aCollection isEmpty ifFalse: [ changesList selectIndex: 1 ].
	self showNode: (aCollection ifEmpty: [ nil ] ifNotEmpty: [ :c | c first ])
]

{ #category : 'initialization' }
GftDiffPresenter >> connectPresenters [
	changesList whenSelectedItemChangedDo: [ :node | self showNode: node ]
]

{ #category : 'layout' }
GftDiffPresenter >> defaultLayout [
	| codePanes |
	codePanes := SpPanedLayout newLeftToRight
		positionOfSlider: 50 percent;
		add: (SpBoxLayout newTopToBottom
			spacing: 4; borderWidth: 4;
			add: 'Alt' expand: false;
			add: oldCodeText expand: true;
			yourself);
		add: (SpBoxLayout newTopToBottom
			spacing: 4; borderWidth: 4;
			add: 'Neu' expand: false;
			add: newCodeText expand: true;
			yourself);
		yourself.
	^ SpPanedLayout newLeftToRight
		positionOfSlider: 25 percent;
		add: (SpBoxLayout newTopToBottom
			spacing: 4; borderWidth: 4;
			add: 'Änderungen' expand: false;
			add: changesList expand: true;
			yourself);
		add: codePanes;
		yourself
]

{ #category : 'initialization' }
GftDiffPresenter >> initializePresenters [
	changesList := self newList.
	changesList display: [ :node | (GftDiffFormatter labelFor: node), (GftDiffFormatter pathFor: node) ].
	oldCodeText := self newCode.
	oldCodeText beNotEditable.
	newCodeText := self newCode.
	newCodeText beNotEditable
]

{ #category : 'actions' }
GftDiffPresenter >> showNode: aNode [
	aNode
		ifNil: [ oldCodeText text: ''. newCodeText text: '' ]
		ifNotNil: [
			oldCodeText text: aNode value leftContents.
			newCodeText text: aNode value rightContents ]
]

{ #category : 'accessing' }
GftDiffPresenter >> windowTitle [
	^ 'Graft -- Diff'
]
