Class {
	#name : 'GftProjectPickerPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'list',
		'okButton',
		'onApplyBlock',
		'initiallySelected',
		'availableList',
		'selectedList',
		'addButton',
		'removeButton',
		'addAllButton',
		'removeAllButton'
	],
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'initialization' }
GftProjectPickerPresenter >> connectPresenters [
	addButton action: [ self moveToSelected ].
	removeButton action: [ self moveToAvailable ].
	addAllButton action: [ self moveAllToSelected ].
	removeAllButton action: [ self moveAllToAvailable ].
	availableList whenActivatedDo: [ :sel | self moveToSelected ].
	selectedList whenActivatedDo: [ :sel | self moveToAvailable ].
	okButton action: [
		| names |
		names := selectedList items collect: [ :p | p name ].
		onApplyBlock ifNotNil: [ onApplyBlock value: names asArray ].
		self delete ]
]

{ #category : 'layout' }
GftProjectPickerPresenter >> defaultLayout [
	| middle body |
	middle := SpBoxLayout newTopToBottom
		spacing: 4;
		add: addAllButton expand: false;
		add: addButton expand: false;
		add: removeButton expand: false;
		add: removeAllButton expand: false;
		yourself.
	body := SpBoxLayout newLeftToRight
		spacing: 6;
		add: (SpBoxLayout newTopToBottom spacing: 4;
			add: 'Verfügbar' expand: false;
			add: availableList expand: true;
			yourself);
		add: middle expand: false;
		add: (SpBoxLayout newTopToBottom spacing: 4;
			add: 'Angezeigt (Sidebar)' expand: false;
			add: selectedList expand: true;
			yourself);
		yourself.
	^ SpBoxLayout newTopToBottom
		spacing: 6; borderWidth: 6;
		add: 'Projekte per → / ← verschieben (Mehrfachauswahl & Doppelklick möglich):' expand: false;
		add: body expand: true;
		add: okButton expand: false;
		yourself
]

{ #category : 'initialization' }
GftProjectPickerPresenter >> initializePresenters [
	availableList := self newList.
	availableList beMultipleSelection.
	availableList display: [ :p | p name ].
	selectedList := self newList.
	selectedList beMultipleSelection.
	selectedList display: [ :p | p name ].
	addButton := self newButton.
	addButton label: '→'.
	removeButton := self newButton.
	removeButton label: '←'.
	addAllButton := self newButton.
	addAllButton label: '≫'.
	removeAllButton := self newButton.
	removeAllButton label: '≪'.
	okButton := self newButton.
	okButton label: 'Übernehmen'.
	self initiallySelected: #()
]

{ #category : 'initialization' }
GftProjectPickerPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: self windowTitle;
		initialExtent: 640@460
]

{ #category : 'accessing' }
GftProjectPickerPresenter >> initiallySelected: aCollectionOfProjectNames [
	"aCollectionOfProjectNames end up on the right (Angezeigt) list, the rest of the image
	projects on the left (Verfügbar). Called before #open, after #initializePresenters created
	the lists."
	| all names |
	initiallySelected := aCollectionOfProjectNames.
	all := GftProject imageProjects.
	names := aCollectionOfProjectNames.
	selectedList items: (self sortedProjects: (all select: [ :p | names includes: p name ])).
	availableList items: (self sortedProjects: (all reject: [ :p | names includes: p name ]))
]

{ #category : 'actions' }
GftProjectPickerPresenter >> moveAllToAvailable [
	availableList items: (self sortedProjects: (availableList items , selectedList items)).
	selectedList items: #()
]

{ #category : 'actions' }
GftProjectPickerPresenter >> moveAllToSelected [
	selectedList items: (self sortedProjects: (selectedList items , availableList items)).
	availableList items: #()
]

{ #category : 'actions' }
GftProjectPickerPresenter >> moveToAvailable [
	| chosen |
	chosen := selectedList selectedItems.
	chosen ifEmpty: [ ^ self ].
	availableList items: (self sortedProjects: (availableList items , chosen)).
	selectedList items: (self sortedProjects: (selectedList items reject: [ :p | chosen includes: p ]))
]

{ #category : 'actions' }
GftProjectPickerPresenter >> moveToSelected [
	| chosen |
	chosen := availableList selectedItems.
	chosen ifEmpty: [ ^ self ].
	selectedList items: (self sortedProjects: (selectedList items , chosen)).
	availableList items: (self sortedProjects: (availableList items reject: [ :p | chosen includes: p ]))
]

{ #category : 'accessing' }
GftProjectPickerPresenter >> onApply: aOneArgBlock [
	"aOneArgBlock is evaluated with an Array of chosen project names when the user confirms."
	onApplyBlock := aOneArgBlock
]

{ #category : 'private' }
GftProjectPickerPresenter >> sortedProjects: aCollection [
	^ (aCollection asSortedCollection: [ :a :b | a name <= b name ]) asOrderedCollection
]

{ #category : 'accessing' }
GftProjectPickerPresenter >> windowTitle [
	^ 'Graft -- Projektauswahl'
]
