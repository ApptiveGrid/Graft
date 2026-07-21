Class {
	#name : 'GftPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'graph',
		'selectedProject',
		'viewProjectNames',
		'roassal',
		'projectSidebar',
		'detailTable',
		'dependentsTable',
		'staleRefsTable',
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
	selectedProject := nil.
	selectedLabel label: 'Custom (', chosenNames size printString, ' Projekte)'.
	detailTable items: #().
	dependentsTable items: #().
	roassal canvas: (GftGraphBuilder
		canvasFor: graph
		projects: (chosenNames collect: [ :n | GftProject named: n ])
		onSelect: [ :proj | self showProject: proj ]).
	self refreshStaleRefsTableForScope: viewProjectNames
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
	| top middle rightSide sidebarBox actionsBox bottomBox |
	sidebarBox := SpBoxLayout newTopToBottom
		add: 'Projekte' expand: false;
		add: projectSidebar expand: true;
		yourself.
	top := SpBoxLayout newLeftToRight
		add: refreshButton expand: false;
		add: selectedLabel expand: true;
		add: bumpButton expand: false;
		yourself.
	rightSide := SpBoxLayout newTopToBottom
		add: 'Abhängigkeiten dieses Projekts' expand: false;
		add: detailTable expand: true;
		add: 'Abhängige Projekte (wer zeigt hierauf)' expand: false;
		add: dependentsTable expand: true;
		yourself.
	middle := SpBoxLayout newLeftToRight
		add: sidebarBox width: 180;
		add: roassal expand: true;
		add: rightSide expand: true;
		yourself.
	actionsBox := SpBoxLayout newLeftToRight
		add: commitCheckbox expand: false;
		add: updateButton expand: false;
		yourself.
	bottomBox := SpBoxLayout newTopToBottom
		add: 'Veraltete Pins im aktuellen Scope (Häkchen = wird bei Aktualisieren angefasst)' expand: false;
		add: staleRefsTable expand: true;
		add: actionsBox expand: false;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: top expand: false;
		add: middle expand: true;
		add: bottomBox expand: false;
		add: planText expand: false;
		yourself
]

{ #category : 'initialization' }
GftPresenter >> initializePresenters [
	graph := GftDependencyGraph build.
	viewProjectNames := GftProject knownProjects collect: [ :p | p name ].
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
	staleRefsTable := self newTable.
	staleRefsTable beMultipleSelection.
	staleRefsTable
		addColumn: (SpStringTableColumn title: 'Projekt' evaluated: [ :r | r ownerProjectName ]);
		addColumn: (SpStringTableColumn title: 'Abhängigkeit' evaluated: [ :r | r declaredName ]);
		addColumn: (SpStringTableColumn title: 'Alter Ref' evaluated: [ :r | self shorten: r url ref ]);
		addColumn: (SpStringTableColumn title: 'Neuer Ref' evaluated: [ :r |
			self shorten: (GftVersionResolver effectiveTipFor: r targetProject) ]).
	refreshButton := self newButton.
	refreshButton label: 'Refresh (fetch)'.
	bumpButton := self newButton.
	bumpButton label: 'Bump-Plan berechnen'.
	commitCheckbox := self newCheckBox.
	commitCheckbox label: 'Committen (statt nur Code ändern)'.
	commitCheckbox state: false.
	updateButton := self newButton.
	updateButton label: 'Ausgewählte Pins aktualisieren'.
	planText := self newText.
	planText beNotEditable
]

{ #category : 'actions' }
GftPresenter >> openCustomPicker [
	| picker |
	picker := GftProjectPickerPresenter new.
	picker initiallySelected: viewProjectNames.
	picker onApply: [ :chosenNames | self applyCustomSelection: chosenNames ].
	picker open
]

{ #category : 'actions' }
GftPresenter >> performUpdate [
	"Applies exactly the rows currently checked/selected in the 'Ausgewählte Pins'-Tabelle --
	not automatically every stale pin of a project. This is the fix for Norbert reporting that
	updating one project bundled in a dependency (FluxBase) he did not want touched yet: the
	table lists every currently-stale pin in scope, pre-selected, and he can deselect any of them
	before clicking this button. commitCheckbox controls whether this only rewrites the affected
	BaselineOf method(s) in the live image (left uncommitted) or also commits locally, one commit
	per owner project -- see GftUpdater class>>updateReferences:commit:. Never pushes."
	| chosen commit preview results summary |
	chosen := staleRefsTable selectedItems asOrderedCollection.
	chosen isEmpty ifTrue: [ ^ self inform: 'Keine Pins ausgewählt (Tabelle unten rechts).' ].
	commit := commitCheckbox state.
	preview := String new writeStream.
	chosen do: [ :ref |
		| newRef |
		newRef := GftVersionResolver effectiveTipFor: ref targetProject.
		newRef ifNotNil: [
			preview nextPutAll: (GftBaselineRewriter previewForReference: ref newRef: newRef) diffText; cr; cr ] ].
	planText text: preview contents.
	(self confirm: (commit
		ifTrue: [ chosen size printString, ' ausgewählte Pin(s) jetzt ändern UND lokal committen (kein Push)?' ]
		ifFalse: [ chosen size printString, ' ausgewählte Pin(s) nur im Code ändern, NICHT committen?' ]))
		ifFalse: [ ^ self ].
	results := GftUpdater updateReferences: chosen commit: commit.
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
	selectedProject
		ifNotNil: [ self showProject: selectedProject ]
		ifNil: [ self refreshStaleRefsTableForScope: viewProjectNames ]
]

{ #category : 'actions' }
GftPresenter >> refreshAll [
	GftVersionResolver fetchAll: GftProject knownProjects.
	self rebuildGraphView
]

{ #category : 'actions' }
GftPresenter >> refreshStaleRefsTableForScope: names [
	| refs |
	refs := (graph allReferences select: [ :r | (names includes: r ownerProjectName) and: [ r isStale ] ]) asOrderedCollection.
	staleRefsTable items: refs.
	staleRefsTable selectAll
]

{ #category : 'actions' }
GftPresenter >> selectAllView [
	viewProjectNames := GftProject knownProjects collect: [ :p | p name ].
	selectedProject := nil.
	selectedLabel label: 'Alle Projekte'.
	detailTable items: #().
	dependentsTable items: #().
	roassal canvas: (GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ]).
	self refreshStaleRefsTableForScope: viewProjectNames
]

{ #category : 'private' }
GftPresenter >> shorten: aStringOrNil [
	aStringOrNil ifNil: [ ^ '' ].
	aStringOrNil size <= 10 ifTrue: [ ^ aStringOrNil ].
	^ (aStringOrNil copyFrom: 1 to: 10), '...'
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
	"Populates the detail/dependents (browsing) tables AND scopes the 'Ausgewählte Pins'
	action table down to just this one project's stale references -- used both by clicking a
	node in the graph and by clicking an individual project row in the sidebar. Does not change
	which projects are drawn in the graph (see #selectAllView/#applyCustomSelection: for that),
	so inspecting/updating one project does not lose a Custom view."
	selectedProject := aProject.
	selectedLabel label: aProject name.
	detailTable items: (graph referencesFrom: aProject name) asOrderedCollection.
	dependentsTable items: (graph dependentsOf: aProject name) asOrderedCollection.
	self refreshStaleRefsTableForScope: { aProject name }
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
