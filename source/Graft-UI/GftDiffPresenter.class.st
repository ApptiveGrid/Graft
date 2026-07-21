Class {
	#name : 'GftDiffPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'textArea'
	],
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'accessing' }
GftDiffPresenter class >> defaultPreferredExtent [
	^ 700@500
]

{ #category : 'instance creation' }
GftDiffPresenter class >> openWithText: aString [
	| p |
	p := self new.
	p text: aString.
	p open.
	^ p
]

{ #category : 'layout' }
GftDiffPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: textArea expand: true;
		yourself
]

{ #category : 'initialization' }
GftDiffPresenter >> initializePresenters [
	textArea := self newText.
	textArea beNotEditable
]

{ #category : 'accessing' }
GftDiffPresenter >> text: aString [
	textArea text: aString
]

{ #category : 'accessing' }
GftDiffPresenter >> windowTitle [
	^ 'Graft -- Diff'
]
