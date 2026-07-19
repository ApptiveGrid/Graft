Class {
	#name : 'GftPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'graph',
		'selectedProject',
		'actionTargetNames',
		'viewProjectNames',
		'roassal',
		'projectSidebar',
		'detailTable',
		'dependentsTable',
		'selectedLabel',
		'planText',
		'refreshButton',
		'bumpButton',
		'updateButton',
		'commitCheckbox'
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

{ #category : 'actions' }
GftPresenter >> applyCustomSelection: chosenNames [
	chosenNames isEmpty ifTrue: [ ^ self inform: 'Keine Projekte ausgewählt.' ].
	viewProjectNames := chosenNames.
	actionTargetNames := chosenNames.
	selectedProject := nil.
	selectedLabel label: 'Custom (', chosenNames size printString, ' Projekte)'.
	detailTable items: #().
	dependentsTable items: #().
	roassal canvas: (GftGraphBuilder
		canvasFor: graph
		projects: (chosenNames collect: [ :n | GftProject named: n ])
		onSelect: [ :proj | self showProject: proj ])
]

{ #category : 'actions' }
GftPresenter >> buildPreviewTextFor: names [
	| stream any |
	stream := String new writeStream.
	any := false.
	names do: [ :name |
		(graph staleOutgoingReferencesOf: name) do: [ :ref |
			| newRef |
			newRef := GftVersionResolver effectiveTipFor: ref targetProject.
			newRef ifNotNil: [
				any := true.
				stream nextPutAll: (GftBaselineRewriter previewForReference: ref newRef: newRef) diffText; cr; cr ] ] ].
	^ any ifTrue: [ stream contents ] ifFalse: [ '' ]
]

{ #category : 'initialization' }
GftPresenter >> connectPresenters [
	projectSidebar whenSelectedItemChangedDo: [ :item | self sidebarSelected: item ].
	refreshButton action: [ self refreshAll ].
	bumpButton action: [ self showBumpPlanForSelectedProject ].
	updateButton action: [ self performUpdate ]
]

{ #category : 'layout' }
GftPresenter >> defaultLayout [
	| top middle rightSide sidebarBox actionsBox |
	sidebarBox := SpBoxLayout newTopToBottom
		add: 'Projekte' expand: false;
		add: projectSidebar expand: true;
		yourself.
	top := SpBoxLayout newLeftToRight
		add: refreshButton expand: false;
		add: selectedLabel expand: true;
		add: bumpButton expand: false;
		yourself.
	actionsBox := SpBoxLayout newLeftToRight
		add: commitCheckbox expand: false;
		add: updateButton expand: false;
		yourself.
	rightSide := SpBoxLayout newTopToBottom
		add: 'Abhängigkeiten dieses Projekts' expand: false;
		add: detailTable expand: true;
		add: 'Abhängige Projekte (wer zeigt hierauf)' expand: false;
		add: dependentsTable expand: true;
		add: actionsBox expand: false;
		yourself.
	middle := SpBoxLayout newLeftToRight
		add: sidebarBox width: 180;
		add: roassal expand: true;
		add: rightSide expand: true;
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
	viewProjectNames := GftProject knownProjects collect: [ :p | p name ].
	actionTargetNames := viewProjectNames.
	roassal := self newRoassal.
	roassal canvas: (GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ]).
	projectSidebar := self newList.
	projectSidebar items: ((OrderedCollection new)
		add: #all;
		add: #custom;
		addAll: (GftProject knownProjects asSortedCollection: [ :a :b | a name <= b name ]);
		yourself).
	projectSidebar display: [ :item |
		item == #all
			ifTrue: [ '◆ Alle' ]
			ifFalse: [ item == #custom ifTrue: [ '◆ Custom...' ] ifFalse: [ '   ', item name ] ] ].
	selectedLabel := self newLabel.
	selectedLabel label: 'Alle Projekte'.
	detailTable := self newTable.
	detailTable
		addColumn: (SpStringTableColumn title: 'Abhängigkeit von' evaluated: [ :r | r declaredName ]);
		addColumn: (SpStringTableColumn title: 'Pin' evaluated: [ :r | r pinKind asString ]);
		addColumn: (SpStringTableColumn title: 'Ref' evaluated: [ :r | r url ref ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Status' evaluated: [ :r |
			r pinKind = #commit
				ifTrue: [ r isStale ifTrue: [ 'veraltet' ] ifFalse: [ 'aktuell' ] ]
				ifFalse: [ '-' ] ]);
		addColumn: (SpStringTableColumn title: 'Bekannt?' evaluated: [ :r | r isExternal ifTrue: [ 'extern' ] ifFalse: [ 'ja' ] ]).
	dependentsTable := self newTable.
	dependentsTable
		addColumn: (SpStringTableColumn title: 'Abhängiges Projekt' evaluated: [ :r | r ownerProjectName ]);
		addColumn: (SpStringTableColumn title: 'Pin' evaluated: [ :r | r pinKind asString ]);
		addColumn: (SpStringTableColumn title: 'Ref' evaluated: [ :r | r url ref ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Status' evaluated: [ :r |
			r pinKind = #commit
				ifTrue: [ r isStale ifTrue: [ 'veraltet' ] ifFalse: [ 'aktuell' ] ]
				ifFalse: [ '-' ] ]).
	refreshButton := self newButton.
	refreshButton label: 'Refresh (fetch)'.
	bumpButton := self newButton.
	bumpButton label: 'Bump-Plan berechnen'.
	commitCheckbox := self newCheckBox.
	commitCheckbox label: 'Committen (statt nur Code ändern)'.
	commitCheckbox state: false.
	updateButton := self newButton.
	updateButton label: 'Aktualisieren'.
	planText := self newText.
	planText beNotEditable
]

{ #category : 'actions' }
GftPresenter >> openCustomPicker [
	| picker |
	picker := GftProjectPickerPresenter new.
	picker initiallySelected: actionTargetNames.
	picker onApply: [ :chosenNames | self applyCustomSelection: chosenNames ].
	picker open
]

{ #category : 'actions' }
GftPresenter >> performUpdate [
	"Applies to whatever is currently the action target: a single project (sidebar row or
	graph-node click), 'Alle', or a 'Custom' subset -- see #showProject:/#selectAllView/
	#applyCustomSelection:. commitCheckbox controls whether this only rewrites the BaselineOf
	method(s) in the live image (left uncommitted, for the user to review/commit themselves)
	or also commits locally in one go per project -- see GftUpdater. Never pushes."
	| commit preview results summary |
	actionTargetNames ifNil: [ ^ self inform: 'Bitte zuerst links ein Projekt oder eine Auswahl wählen.' ].
	commit := commitCheckbox state.
	preview := self buildPreviewTextFor: actionTargetNames.
	preview isEmpty ifTrue: [ ^ self inform: 'Keine veralteten Pins in der aktuellen Auswahl.' ].
	planText text: preview.
	(self confirm: (commit
		ifTrue: [ 'Änderungen jetzt anwenden UND lokal committen (kein Push)?' ]
		ifFalse: [ 'Nur den Code jetzt ändern, NICHT committen?' ]))
		ifFalse: [ ^ self ].
	results := GftUpdater updateProjects: actionTargetNames commit: commit.
	results isEmpty ifTrue: [ ^ self inform: 'Nichts zu tun.' ].
	summary := String new writeStream.
	results do: [ :r | summary nextPutAll: r summary; cr; cr ].
	planText text: summary contents.
	self rebuildGraphView
]

{ #category : 'actions' }
GftPresenter >> rebuildGraphView [
	graph := GftDependencyGraph build.
	roassal canvas: (viewProjectNames size = GftProject knownProjects size
		ifTrue: [ GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ] ]
		ifFalse: [ GftGraphBuilder
			canvasFor: graph
			projects: (viewProjectNames collect: [ :n | GftProject named: n ])
			onSelect: [ :proj | self showProject: proj ] ]).
	selectedProject ifNotNil: [ self showProject: selectedProject ]
]

{ #category : 'actions' }
GftPresenter >> refreshAll [
	GftVersionResolver fetchAll: GftProject knownProjects.
	self rebuildGraphView
]

{ #category : 'actions' }
GftPresenter >> selectAllView [
	viewProjectNames := GftProject knownProjects collect: [ :p | p name ].
	actionTargetNames := viewProjectNames.
	selectedProject := nil.
	selectedLabel label: 'Alle Projekte'.
	detailTable items: #().
	dependentsTable items: #().
	roassal canvas: (GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ])
]

{ #category : 'actions' }
GftPresenter >> showBumpPlanForSelectedProject [
	| newCommit plan stream |
	selectedProject ifNil: [ ^ self inform: 'Bitte zuerst ein Projekt anklicken (Graph oder Sidebar).' ].
	newCommit := GftVersionResolver latestCommitFor: selectedProject ifUnknown: [ nil ].
	newCommit ifNil: [ ^ self inform: 'Kein bekannter aktueller Commit für ', selectedProject name, ' -- erst Refresh drücken.' ].
	plan := GftBumpPlan for: selectedProject name newCommit: newCommit usingGraph: graph.
	stream := String new writeStream.
	plan isEmpty
		ifTrue: [ stream nextPutAll: 'Keine BaselineOf müsste angepasst werden -- niemand referenziert ', selectedProject name, ' commit-gepinnt.' ]
		ifFalse: [
			stream nextPutAll: 'Bump-Plan für ', selectedProject name, ' -> ', newCommit; cr; cr.
			plan concreteSteps do: [ :step |
				stream nextPutAll: (GftBaselineRewriter previewFor: step) diffText; cr; cr ].
			plan pendingSteps isEmpty ifFalse: [
				stream nextPutAll: '--- weitere Kaskade (erst nach Anwendung der obigen Schritte konkret berechenbar) ---'; cr.
				plan pendingSteps do: [ :step | stream nextPutAll: step printString; cr ] ].
			plan floatingDependents isEmpty ifFalse: [
				stream nextPutAll: '--- floatet automatisch, keine Änderung nötig ---'; cr.
				plan floatingDependents do: [ :ref | stream nextPutAll: ref printString; cr ] ] ].
	planText text: stream contents
]

{ #category : 'actions' }
GftPresenter >> showProject: aProject [
	"Populates the detail/dependents tables and makes aProject the single target for the
	Update button -- used both by clicking a node in the graph and by clicking an individual
	project row in the sidebar. Deliberately does not touch the sidebar selection or which
	projects are currently drawn in the graph (see #selectAllView/#applyCustomSelection: for
	that), so inspecting one project does not lose a Custom view."
	selectedProject := aProject.
	actionTargetNames := { aProject name }.
	selectedLabel label: aProject name.
	detailTable items: (graph referencesFrom: aProject name) asOrderedCollection.
	dependentsTable items: (graph dependentsOf: aProject name) asOrderedCollection
]

{ #category : 'actions' }
GftPresenter >> sidebarSelected: item [
	item ifNil: [ ^ self ].
	item == #all ifTrue: [ ^ self selectAllView ].
	item == #custom ifTrue: [ ^ self openCustomPicker ].
	self showProject: item
]

{ #category : 'accessing' }
GftPresenter >> windowTitle [
	^ 'Graft -- Metacello Dependency Graph'
]
