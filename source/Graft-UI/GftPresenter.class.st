Class {
	#name : 'GftPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'graph',
		'selectedProject',
		'roassal',
		'detailTable',
		'selectedLabel',
		'planText',
		'refreshButton',
		'bumpButton'
	],
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'accessing' }
GftPresenter class >> defaultPreferredExtent [
	^ 1150@780
]

{ #category : 'instance creation' }
GftPresenter class >> open [
	^ self new open
]

{ #category : 'initialization' }
GftPresenter >> connectPresenters [
	refreshButton action: [ self refreshAll ].
	bumpButton action: [ self showBumpPlanForSelectedProject ]
]

{ #category : 'layout' }
GftPresenter >> defaultLayout [
	| top middle |
	top := SpBoxLayout newLeftToRight
		add: refreshButton expand: false;
		add: selectedLabel expand: true;
		add: bumpButton expand: false;
		yourself.
	middle := SpBoxLayout newLeftToRight
		add: roassal expand: true;
		add: detailTable expand: true;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: top expand: false;
		add: middle expand: true;
		add: planText expand: false;
		yourself
]

{ #category : 'initialization' }
GftPresenter >> initializePresenters [
	graph := GftDependencyGraph build.
	roassal := self newRoassal.
	roassal canvas: (GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ]).
	selectedLabel := self newLabel.
	selectedLabel label: 'Projekt anklicken...'.
	detailTable := self newTable.
	detailTable
		addColumn: (SpStringTableColumn title: 'Ziel' evaluated: [ :r | r declaredName ]);
		addColumn: (SpStringTableColumn title: 'Pin' evaluated: [ :r | r pinKind asString ]);
		addColumn: (SpStringTableColumn title: 'Ref' evaluated: [ :r | r url ref ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Status' evaluated: [ :r |
			r pinKind = #commit
				ifTrue: [ r isStale ifTrue: [ 'veraltet' ] ifFalse: [ 'aktuell' ] ]
				ifFalse: [ '-' ] ]);
		addColumn: (SpStringTableColumn title: 'Bekannt?' evaluated: [ :r | r isExternal ifTrue: [ 'extern' ] ifFalse: [ 'ja' ] ]).
	refreshButton := self newButton.
	refreshButton label: 'Refresh (fetch)'.
	bumpButton := self newButton.
	bumpButton label: 'Bump-Plan berechnen'.
	planText := self newText.
	planText beNotEditable
]

{ #category : 'actions' }
GftPresenter >> refreshAll [
	GftVersionResolver fetchAll: GftProject knownProjects.
	graph := GftDependencyGraph build.
	roassal canvas: (GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ]).
	selectedProject ifNotNil: [ self showProject: selectedProject ]
]

{ #category : 'actions' }
GftPresenter >> showBumpPlanForSelectedProject [
	| newCommit plan stream |
	selectedProject ifNil: [ ^ self inform: 'Bitte zuerst ein Projekt im Graph anklicken.' ].
	newCommit := GftVersionResolver latestCommitFor: selectedProject ifUnknown: [ nil ].
	newCommit ifNil: [ ^ self inform: 'Kein bekannter aktueller Commit fuer ', selectedProject name, ' -- erst Refresh druecken.' ].
	plan := GftBumpPlan for: selectedProject name newCommit: newCommit usingGraph: graph.
	stream := String new writeStream.
	plan isEmpty
		ifTrue: [ stream nextPutAll: 'Keine BaselineOf muesste angepasst werden -- niemand referenziert ', selectedProject name, ' commit-gepinnt.' ]
		ifFalse: [
			stream nextPutAll: 'Bump-Plan fuer ', selectedProject name, ' -> ', newCommit; cr; cr.
			plan concreteSteps do: [ :step |
				stream nextPutAll: (GftBaselineRewriter previewFor: step) diffText; cr; cr ].
			plan pendingSteps isEmpty ifFalse: [
				stream nextPutAll: '--- weitere Kaskade (erst nach Anwendung der obigen Schritte konkret berechenbar) ---'; cr.
				plan pendingSteps do: [ :step | stream nextPutAll: step printString; cr ] ].
			plan floatingDependents isEmpty ifFalse: [
				stream nextPutAll: '--- floatet automatisch, keine Aenderung noetig ---'; cr.
				plan floatingDependents do: [ :ref | stream nextPutAll: ref printString; cr ] ] ].
	planText text: stream contents
]

{ #category : 'actions' }
GftPresenter >> showProject: aProject [
	selectedProject := aProject.
	selectedLabel label: aProject name.
	detailTable items: (graph referencesFrom: aProject name) asOrderedCollection
]

{ #category : 'accessing' }
GftPresenter >> windowTitle [
	^ 'Graft -- Metacello Dependency Graph'
]
