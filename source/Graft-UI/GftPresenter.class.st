Class {
	#name : 'GftPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'graph',
		'selectedProject',
		'roassal',
		'detailTable',
		'dependentsTable',
		'selectedLabel',
		'planText',
		'refreshButton',
		'bumpButton',
		'updateProjectButton',
		'updateAllButton'
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
	bumpButton action: [ self showBumpPlanForSelectedProject ].
	updateProjectButton action: [ self updateSelectedProject ].
	updateAllButton action: [ self updateAllProjects ]
]

{ #category : 'layout' }
GftPresenter >> defaultLayout [
	| top middle rightSide |
	top := SpBoxLayout newLeftToRight
		add: refreshButton expand: false;
		add: selectedLabel expand: true;
		add: bumpButton expand: false;
		add: updateProjectButton expand: false;
		add: updateAllButton expand: false;
		yourself.
	rightSide := SpBoxLayout newTopToBottom
		add: 'Abhängigkeiten dieses Projekts' expand: false;
		add: detailTable expand: true;
		add: 'Abhängige Projekte (wer zeigt hierauf)' expand: false;
		add: dependentsTable expand: true;
		yourself.
	middle := SpBoxLayout newLeftToRight
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
	roassal := self newRoassal.
	roassal canvas: (GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ]).
	selectedLabel := self newLabel.
	selectedLabel label: 'Projekt anklicken...'.
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
	updateProjectButton := self newButton.
	updateProjectButton label: 'Projekt aktualisieren'.
	updateAllButton := self newButton.
	updateAllButton label: 'Alle aktualisieren'.
	planText := self newText.
	planText beNotEditable
]

{ #category : 'actions' }
GftPresenter >> rebuildGraphView [
	graph := GftDependencyGraph build.
	roassal canvas: (GftGraphBuilder canvasFor: graph onSelect: [ :proj | self showProject: proj ]).
	selectedProject ifNotNil: [ self showProject: selectedProject ]
]

{ #category : 'actions' }
GftPresenter >> refreshAll [
	GftVersionResolver fetchAll: GftProject knownProjects.
	self rebuildGraphView
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
	detailTable items: (graph referencesFrom: aProject name) asOrderedCollection.
	dependentsTable items: (graph dependentsOf: aProject name) asOrderedCollection
]

{ #category : 'actions' }
GftPresenter >> updateAllProjects [
	"Runs the full cascade: repeatedly updates every currently-safe, currently-stale project
	(each in its own local commit, never pushed) until nothing more changes -- see GftUpdater
	class>>updateAll. Asks for confirmation first, showing which projects currently have
	fixable stale pins."
	| staleProjectNames results summary |
	staleProjectNames := graph projects
		select: [ :p | (graph staleOutgoingReferencesOf: p name) isNotEmpty ]
		thenCollect: [ :p | p name ].
	staleProjectNames isEmpty ifTrue: [ ^ self inform: 'Nichts zu tun -- keine veralteten Pins gefunden.' ].
	(self confirm: 'Kaskade jetzt anwenden für: ', (staleProjectNames fold: [ :a :b | a, ', ', b ]), '? (mehrere lokale Commits möglich, kein Push)')
		ifFalse: [ ^ self ].
	results := GftUpdater updateAll.
	summary := String new writeStream.
	results do: [ :r | summary nextPutAll: r summary; cr; cr ].
	planText text: summary contents.
	self rebuildGraphView
]

{ #category : 'actions' }
GftPresenter >> updateSelectedProject [
	"Fixes every currently-stale outgoing pin of the selected project in one local commit
	(never pushes) -- see GftUpdater class>>updateProject:usingGraph:. Shows a preview and
	asks for confirmation first."
	| staleRefs previewText result |
	selectedProject ifNil: [ ^ self inform: 'Bitte zuerst ein Projekt im Graph anklicken.' ].
	staleRefs := graph staleOutgoingReferencesOf: selectedProject name.
	staleRefs isEmpty ifTrue: [ ^ self inform: selectedProject name, ' hat keine veralteten Pins.' ].
	previewText := String new writeStream.
	staleRefs do: [ :ref |
		| newRef |
		newRef := GftVersionResolver effectiveTipFor: ref targetProject.
		previewText
			nextPutAll: (GftBaselineRewriter previewForReference: ref newRef: newRef) diffText;
			cr; cr ].
	planText text: previewText contents.
	(self confirm: 'Diese Änderung(en) an ', selectedProject name, ' jetzt lokal committen (kein Push)?')
		ifFalse: [ ^ self ].
	result := GftUpdater updateProject: selectedProject usingGraph: graph.
	planText text: result summary.
	self rebuildGraphView
]

{ #category : 'accessing' }
GftPresenter >> windowTitle [
	^ 'Graft -- Metacello Dependency Graph'
]
