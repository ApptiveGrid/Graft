Class {
	#name : 'GftProjectPickerPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'list',
		'okButton',
		'onApplyBlock',
		'initiallySelected'
	],
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'initialization' }
GftProjectPickerPresenter >> connectPresenters [
	initiallySelected ifNotNil: [ :names |
		list selectItems: (list items select: [ :p | names includes: p name ]) ].
	okButton action: [
		| chosenNames |
		chosenNames := list selectedItems collect: [ :p | p name ].
		onApplyBlock ifNotNil: [ onApplyBlock value: chosenNames asArray ].
		self delete ]
]

{ #category : 'layout' }
GftProjectPickerPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: 'Projekte auswählen (Mehrfachauswahl):' expand: false;
		add: list expand: true;
		add: okButton expand: false;
		yourself
]

{ #category : 'initialization' }
GftProjectPickerPresenter >> initializePresenters [
	list := self newList.
	list items: (GftProject knownProjects asSortedCollection: [ :a :b | a name <= b name ]) asOrderedCollection.
	list display: [ :p | p name ].
	list beMultipleSelection.
	okButton := self newButton.
	okButton label: 'Übernehmen'
]

{ #category : 'accessing' }
GftProjectPickerPresenter >> initiallySelected: aCollectionOfProjectNames [
	initiallySelected := aCollectionOfProjectNames
]

{ #category : 'accessing' }
GftProjectPickerPresenter >> onApply: aOneArgBlock [
	"aOneArgBlock is evaluated with an Array of chosen project names when the user confirms."
	onApplyBlock := aOneArgBlock
]

{ #category : 'accessing' }
GftProjectPickerPresenter >> windowTitle [
	^ 'Graft -- Custom-Auswahl'
]
