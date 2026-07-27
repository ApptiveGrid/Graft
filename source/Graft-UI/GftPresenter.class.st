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
		'redrawButton',
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

{ #category : 'menu' }
GftPresenter class >> menuCommandOn: aBuilder [
	"Adds a 'Graft' entry under the Tools group in Pharos top World menu (visible whenever
	this package is loaded), so Norbert doesnt need to evaluate GftPresenter new open by hand
	every time he wants to check the ApptiveGrid dependency graph."
	<worldMenu>
	(aBuilder item: #Graft)
		parent: #Tools;
		action: [ self new open ];
		order: 50;
		help: 'Öffnet Graft: Metacello-BaselineOf-Dependency-Verwaltung über die ApptiveGrid-Projekte.'
]

{ #category : 'instance creation' }
GftPresenter class >> open [
	^ self new open
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (actions) - 14 selector(s)) - 6 selector(s)) - 6 selector(s)) - 6 selector(s)' }
GftPresenter >> applyCustomSelection: chosenNames [
	"Persists the chosen project names class-side (GftProject selectedProjectNames:) so the
	sidebar/graph scope survives image restarts and needs no code edit to start showing a freshly
	cloned project such as OpenAPI. An empty choice clears the selection -> back to all image
	projects. Then rebuilds everything via #reloadProjects."
	chosenNames isEmpty
		ifTrue: [ GftProject clearSelection ]
		ifFalse: [ GftProject selectedProjectNames: chosenNames ].
	self reloadProjects
]

{ #category : 'initialization' }
GftPresenter >> connectPresenters [
	projectSidebar whenSelectedItemChangedDo: [ :item | self sidebarSelected: item ].
	refreshButton action: [ self refreshAll ].
	redrawButton action: [ self rebuildGraphView ].
	bumpButton action: [ self showBumpPlanForSelectedProject ].
	updateButton action: [ self performUpdate ]
]

{ #category : 'layout' }
GftPresenter >> defaultLayout [
	"Resizable throughout (SpPanedLayout everywhere two regions sit side by side or stacked,
	so Norbert can drag to resize instead of living with fixed proportions) and with generous
	spacing/borderWidth for padding (Norbert 2026-07-20: the tight default layout did not look
	good). actionsBox gives commitCheckbox expand: true (Norbert 2026-07-21: its label text ran
	into updateButton when both sat at their natural width side by side) so the checkbox owns
	the remaining row width and updateButton is pinned flush against the right edge.

	redrawButton (2026-07-21) sits next to refreshButton: refreshButton does a real network
	fetch of all known repos before rebuilding (#refreshAll), which is unnecessary and slower
	when the change is purely local -- e.g. Norbert just committed something via Iceberg in his
	own image and wants to see the updated graph without waiting on a fetch, or without closing
	and reopening this whole window. redrawButton just calls #rebuildGraphView directly (no
	fetch), which re-reads whatever is currently loaded/committed and redraws the canvas."
	| top rightSide sidebarBox actionsBox bottomBox middlePaned outerPaned mainPaned |
	sidebarBox := SpBoxLayout newTopToBottom
		spacing: 6; borderWidth: 6;
		add: 'Projekte' expand: false;
		add: projectSidebar expand: true;
		yourself.
	top := SpBoxLayout newLeftToRight
		spacing: 8; borderWidth: 8;
		add: refreshButton expand: false;
		add: redrawButton expand: false;
		add: selectedLabel expand: true;
		add: bumpButton expand: false;
		yourself.
	rightSide := SpPanedLayout newTopToBottom
		positionOfSlider: 50 percent;
		add: (SpBoxLayout newTopToBottom
			spacing: 6; borderWidth: 6;
			add: 'Abhängigkeiten dieses Projekts' expand: false;
			add: detailTable expand: true;
			yourself);
		add: (SpBoxLayout newTopToBottom
			spacing: 6; borderWidth: 6;
			add: 'Abhängige Projekte (wer zeigt hierauf)' expand: false;
			add: dependentsTable expand: true;
			yourself);
		yourself.
	middlePaned := SpPanedLayout newLeftToRight
		positionOfSlider: 60 percent;
		add: roassal;
		add: rightSide;
		yourself.
	outerPaned := SpPanedLayout newLeftToRight
		positionOfSlider: 15 percent;
		add: sidebarBox;
		add: middlePaned;
		yourself.
	actionsBox := SpBoxLayout newLeftToRight
		spacing: 8; borderWidth: 6;
		add: commitCheckbox expand: true;
		add: updateButton expand: false;
		yourself.
	bottomBox := SpBoxLayout newTopToBottom
		spacing: 6; borderWidth: 6;
		add: 'Veraltete Pins im aktuellen Scope (Häkchen = wird bei Aktualisieren angefasst)' expand: false;
		add: staleRefsTable expand: true;
		add: actionsBox expand: false;
		yourself.
	mainPaned := SpPanedLayout newTopToBottom
		positionOfSlider: 65 percent;
		add: outerPaned;
		add: bottomBox;
		yourself.
	^ SpBoxLayout newTopToBottom
		spacing: 6; borderWidth: 6;
		add: top expand: false;
		add: mainPaned expand: true;
		add: planText expand: false;
		yourself
]

{ #category : 'actions' }
GftPresenter >> generateUpdateBranchName [
	| now |
	now := DateAndTime now.
	^ 'graft/update-', now year printString, (now month printPaddedWith: $0 to: 2), (now dayOfMonth printPaddedWith: $0 to: 2), '-', (now hour printPaddedWith: $0 to: 2), (now minute printPaddedWith: $0 to: 2), (now second printPaddedWith: $0 to: 2)
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (initialization) - 2 selector(s)) - 1 selector(s)) - 1 selector(s)) - 1 selector(s)' }
GftPresenter >> initializePresenters [
	graph := GftDependencyGraph build.
	viewProjectNames := GftProject managedProjectNames.
	roassal := self newRoassal.
	roassal script: [ :c | GftGraphBuilder renderGraph: graph projects: graph projects onSelect: [ :proj | self showProject: proj ] on: c ].
	projectSidebar := self newList.
	projectSidebar items: ((OrderedCollection new)
		add: #all;
		add: #custom;
		addAll: (GftProject managedProjects asSortedCollection: [ :a :b | a name <= b name ]);
		yourself).
	projectSidebar display: [ :item |
		item == #all
			ifTrue: [ '◆ Alle (Auswahl zurücksetzen)' ]
			ifFalse: [ item == #custom ifTrue: [ '◆ Auswahl ändern…' ] ifFalse: [ '   ', item name ] ] ].
	selectedLabel := self newLabel.
	self updateSelectedLabel.
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
	redrawButton := self newButton.
	redrawButton label: 'Neu zeichnen'.
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
GftPresenter >> offerBranchSwitchFor: aCollectionOfProjectNames [
	"For every project among aCollectionOfProjectNames that is not on its tracked branch
	(GftUpdater class>>needsBranchDecision:), asks once whether to create/switch to a fresh
	branch for this update instead. All projects that say yes share the same generated branch
	name (one per Aktualisieren click), so a coordinated multi-repo bump lands on
	same-named branches. Declining leaves that project checked out as-is."
	| branchName |
	branchName := nil.
	aCollectionOfProjectNames do: [ :name |
		| proj |
		proj := GftProject named: name.
		(GftUpdater needsBranchDecision: proj) ifTrue: [
			(self confirm: proj name, ' steht auf Branch ', (GftUpdater currentBranchDescriptionFor: proj), ', nicht auf dem getrackten ', proj trackedRef, '. Neuen Branch für dieses Update anlegen und dorthin wechseln?')
				ifTrue: [
					branchName ifNil: [ branchName := self generateUpdateBranchName ].
					GftUpdater switchToUpdateBranch: branchName for: proj ] ] ]
]

{ #category : 'actions' }
GftPresenter >> offerIgnoreUnrelatedChangesFor: aCollectionOfProjectNames [
	"If any project among aCollectionOfProjectNames already has unrelated uncommitted changes
	(GftUpdater class>>unrelatedModifiedPackagesFor:), lists them and asks once whether to
	bundle them into this update anyway instead of refusing outright (Norbert 2026-07-21:
	sometimes wants to commit a dependency-bump together with other in-progress work already
	sitting in the same repo -- combine with #offerBranchSwitchFor: first if that other work
	should land on its own branch rather than whatever was checked out). Answers whether the
	caller should pass ignoringUnrelatedChanges: true to GftUpdater."
	| affected description |
	affected := aCollectionOfProjectNames select: [ :name |
		(GftUpdater unrelatedModifiedPackagesFor: (GftProject named: name)) isNotEmpty ].
	affected isEmpty ifTrue: [ ^ false ].
	description := String new writeStream.
	affected do: [ :name |
		| pkgs |
		pkgs := GftUpdater unrelatedModifiedPackagesFor: (GftProject named: name).
		description
			nextPutAll: name, ': ', ((pkgs collect: [ :p | p name ]) fold: [ :a :b | a, ', ', b ]);
			cr ].
	^ self confirm: 'Folgende Projekte haben bereits unabhängige, nicht committete Änderungen:'
		, (String with: Character cr), description contents
		, 'Trotzdem zusammen mit dem Dependency-Update committen?'
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (actions) - 14 selector(s)) - 6 selector(s)) - 6 selector(s)) - 6 selector(s)' }
GftPresenter >> openCustomPicker [
	| picker |
	picker := GftProjectPickerPresenter new.
	picker initiallySelected: GftProject managedProjectNames.
	picker onApply: [ :chosenNames | self applyCustomSelection: chosenNames ].
	picker open
]

{ #category : 'actions' }
GftPresenter >> performUpdate [
	"Applies exactly the rows currently checked/selected in the 'Ausgewählte Pins'-Tabelle --
	not automatically every stale pin of a project. commitCheckbox controls whether this only
	rewrites the affected BaselineOf method(s) in the live image (left uncommitted) or also
	commits locally, one commit per owner project -- see GftUpdater class>>updateReferences:
	commit:ignoringUnrelatedChanges:. Never pushes. Before applying, asks separately for every
	involved project that is not on its tracked branch whether to create/switch to a fresh
	update branch instead of insisting on the tracked ref (see #offerBranchSwitchFor:), and for
	every involved project that already has unrelated uncommitted changes whether to bundle
	them in anyway rather than refusing outright (see #offerIgnoreUnrelatedChangesFor:) --
	declining either just proceeds as before (current branch / still blocked, respectively)."
	| chosen commit preview results summary ownerProjectNames ignoreUnrelated |
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
	ownerProjectNames := (chosen collect: [ :r | r ownerProjectName ]) asSet.
	self offerBranchSwitchFor: ownerProjectNames.
	ignoreUnrelated := self offerIgnoreUnrelatedChangesFor: ownerProjectNames.
	results := GftUpdater updateReferences: chosen commit: commit ignoringUnrelatedChanges: ignoreUnrelated.
	summary := String new writeStream.
	results do: [ :r | summary nextPutAll: r summary; cr; cr ].
	planText text: summary contents.
	self rebuildGraphView
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (actions) - 14 selector(s)) - 6 selector(s)) - 6 selector(s)) - 6 selector(s)' }
GftPresenter >> rebuildGraphView [
	"Rebuilds the dependency graph from whatever is currently loaded/committed (no network
	access -- see GftDependencyGraph class>>build) and repaints the Roassal canvas. The view is
	driven by SpRoassalPresenter's script: block (set in #initializePresenters, reads the current
	graph ivar), so #refresh re-runs it against a fresh canvas -- required because the adapter
	rebuilds the canvas on refresh and a canvas handed in via #canvas: would not survive that.
	The drawn set is exactly GftProject managedProjects (the graph is built over that set)."
	graph := GftDependencyGraph build.
	roassal refresh.
	selectedProject
		ifNotNil: [ self showProject: selectedProject ]
		ifNil: [ self refreshStaleRefsTableForScope: viewProjectNames ]
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (actions) - 14 selector(s)) - 6 selector(s)) - 6 selector(s)) - 6 selector(s)' }
GftPresenter >> refreshAll [
	GftVersionResolver fetchAll: GftProject managedProjects.
	self rebuildGraphView
]

{ #category : 'actions' }
GftPresenter >> refreshStaleRefsTableForScope: names [
	"Every currently-stale reference touching the given scope on EITHER side -- both this
	scopes own outgoing stale pins (it needs to catch up to something) and other projects
	stale pins pointing at something in scope (they need to catch up to it). Fixed 2026-07-20:
	previously only looked at ownerProjectName, so clicking e.g. apptivescript (which has no
	stale outgoing pins of its own) showed an empty table even though apptive-base -- visible
	right there in the Abhaengige-Projekte table as veraltet -- has a stale pin to apptivescript;
	Aktualisieren then had nothing to act on."
	| refs |
	refs := (graph allReferences select: [ :r |
		r isStale and: [ (names includes: r ownerProjectName) or: [ names includes: r targetProject name ] ] ])
		asOrderedCollection.
	staleRefsTable items: refs.
	staleRefsTable selectAll
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (actions) - 14 selector(s)) - 6 selector(s)) - 6 selector(s)) - 6 selector(s)' }
GftPresenter >> reloadProjects [
	"Rebuilds graph, sidebar list and canvas after the persisted project selection changed
	(Custom-picker apply, or reset via the sidebars Alle entry). The Roassal view is driven by the
	script: block set in #initializePresenters (which reads the current graph), so a plain #refresh
	repaints it. Keeps the currently-clicked project focused if it is still in scope."
	graph := GftDependencyGraph build.
	viewProjectNames := GftProject managedProjectNames.
	projectSidebar items: ((OrderedCollection new)
		add: #all;
		add: #custom;
		addAll: (GftProject managedProjects asSortedCollection: [ :a :b | a name <= b name ]);
		yourself).
	self updateSelectedLabel.
	detailTable items: #().
	dependentsTable items: #().
	roassal refresh.
	(selectedProject notNil and: [ viewProjectNames includes: selectedProject name ])
		ifTrue: [ self showProject: selectedProject ]
		ifFalse: [
			selectedProject := nil.
			self refreshStaleRefsTableForScope: viewProjectNames ]
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (actions) - 14 selector(s)) - 6 selector(s)) - 6 selector(s)) - 6 selector(s)' }
GftPresenter >> selectAllView [
	"Sidebar ◆ Alle: clears the persisted Custom selection so every image project shows again."
	GftProject clearSelection.
	self reloadProjects
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
	action table down to just this one projects stale references -- used both by clicking a
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

{ #category : 'Protocol (Protocol (Protocol (Protocol (private) - 2 selector(s)) - 1 selector(s)) - 1 selector(s)) - 1 selector(s)' }
GftPresenter >> updateSelectedLabel [
	"Reflects the current scope in the header label: either the persisted Custom selection size or,
	when no selection is set, the full image-project count (see GftProject managedProjects)."
	selectedLabel label: (GftProject hasSelection
		ifTrue: [ 'Auswahl: ', GftProject managedProjects size printString, ' Projekte' ]
		ifFalse: [ 'Alle Projekte im Image (', GftProject imageProjects size printString, ')' ])
]

{ #category : 'accessing' }
GftPresenter >> windowTitle [
	^ 'Graft -- Metacello Dependency Graph'
]
