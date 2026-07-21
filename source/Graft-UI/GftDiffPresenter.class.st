Class {
	#name : 'GftDiffPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'changesList',
		'diffView'
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
	^ SpPanedLayout newLeftToRight
		positionOfSlider: 25 percent;
		add: (SpBoxLayout newTopToBottom
			spacing: 4; borderWidth: 4;
			add: 'Änderungen' expand: false;
			add: changesList expand: true;
			yourself);
		add: diffView;
		yourself
]

{ #category : 'initialization' }
GftDiffPresenter >> initializePresenters [
	changesList := self newList.
	changesList display: [ :node | (GftDiffFormatter labelFor: node), (GftDiffFormatter pathFor: node) ].
	diffView := self newDiff.
	diffView
		leftLabel: 'Alt';
		rightLabel: 'Neu'
]

{ #category : 'actions' }
GftDiffPresenter >> showNode: aNode [
	aNode
		ifNil: [ diffView leftText: ''; rightText: '' ]
		ifNotNil: [
			diffView
				leftText: aNode value leftContents;
				rightText: aNode value rightContents ]
]

{ #category : 'accessing' }
GftDiffPresenter >> windowTitle [
	^ 'Graft -- Diff'
]
