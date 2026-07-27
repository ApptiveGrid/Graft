Class {
	#name : 'GftGraphBuilder',
	#superclass : 'Object',
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'building' }
GftGraphBuilder class >> addContextMenuTo: composite project: proj graph: aGraph [
	"Right-click menu on a graph node: one entry per distinct dependent whose pin to this
	project is stale, each opening a text diff of what actually changed in this project between
	that pin and its current effective tip (see GftDiffFormatter). Only relevant for a project
	that GftDependencyGraph>>hasStaleDependents: -- for others the menu just says so."
	composite addInteraction: (RSMenuActivable new
		menuDo: [ :menu :shape |
			| staleDeps |
			staleDeps := aGraph staleDependentsOf: proj name.
			staleDeps isEmpty
				ifTrue: [ menu add: 'Keine veralteten Abhängigen' target: self selector: #yourself ]
				ifFalse: [
					staleDeps do: [ :ref |
						menu
							add: 'Diff: ', ref ownerProjectName, ' hinkt hinterher (', (ref url ref), ' -> aktuell)'
							target: self
							selector: #showDiffForReference:
							argument: ref ] ] ])
]

{ #category : 'building' }
GftGraphBuilder class >> canvasFor: aGraph onSelect: aOneArgBlock [
	^ self canvasFor: aGraph projects: aGraph projects onSelect: aOneArgBlock
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (building) - 5 selector(s)) - 2 selector(s)) - 2 selector(s)) - 2 selector(s)' }
GftGraphBuilder class >> canvasFor: aGraph projects: projectsToShow onSelect: aOneArgBlock [
	"Builds and answers a fresh RSCanvas for projectsToShow. Convenience wrapper around
	#renderGraph:projects:onSelect:on: for callers/tests that want a standalone canvas; the GUI
	itself renders through SpRoassalPresenter's script: block (see GftPresenter) so the graph
	survives a canvas #refresh. Node fill: yellow if hasStaleDependents:, light green if no own
	stale outgoing pins, else gray. Border red+thick if the project has stale outgoing pins OR its
	baseline failed to parse (GftDependencyGraph hasParseFailure: -> no edges). One arrowed edge per
	reference, dashed for a plain #branch pin, short commit/branch marker at the midpoint."
	^ self renderGraph: aGraph projects: projectsToShow onSelect: aOneArgBlock on: RSCanvas new
]

{ #category : 'colors' }
GftGraphBuilder class >> colorFor: aProjectName usingGraph: aGraph [
	"Node fill color, three states in priority order (Norbert, 2026-07-21): yellow if this
	project has shipped something not every dependent has picked up yet
	(GftDependencyGraph>>hasStaleDependents:) -- takes priority regardless of this projects
	own status, since thats the more urgent signal for whoever looks at the graph; otherwise
	light green if this project itself has no stale outgoing pins (its own dependencies are
	all current, GftDependencyGraph>>staleOutgoingReferencesOf: empty); otherwise plain gray
	(no stale dependents, but this project itself still needs to catch up to its own
	dependencies -- also visible via the red/thick border, see #canvasFor:projects:onSelect:)."
	(aGraph hasStaleDependents: aProjectName) ifTrue: [ ^ Color yellow ].
	(aGraph staleOutgoingReferencesOf: aProjectName) isEmpty ifTrue: [ ^ Color lightGreen ].
	^ Color veryLightGray
]

{ #category : 'colors' }
GftGraphBuilder class >> colorForPinKind: aSymbol [
	aSymbol caseOf: {
		[ #commit ] -> [ ^ Color black ].
		[ #branch ] -> [ ^ Color gray ].
		[ #none ] -> [ ^ Color veryLightGray darker ] }
]

{ #category : 'colors' }
GftGraphBuilder class >> colorForReference: aReference [
	"An individual edges color: yellow if this specific pin is stale (so you can see directly
	which dependent is the one lagging behind, not just that the target has some lagging
	dependent somewhere) -- otherwise the plain pin-kind color."
	aReference isStale ifTrue: [ ^ Color yellow ].
	^ self colorForPinKind: aReference pinKind
]

{ #category : 'colors' }
GftGraphBuilder class >> displayKeyFor: aReference [
	"Grouping key for edge styling: #stale for any currently-stale commit pin (drawn yellow,
	regardless of pin kind -- staleness only applies to #commit pins anyway), otherwise the
	plain pin kind."
	aReference isStale ifTrue: [ ^ #stale ].
	^ aReference pinKind
]

{ #category : 'colors' }
GftGraphBuilder class >> edgeLabelTextFor: aReference [
	"Short text shown at the midpoint of an edge: gits own 7-char abbreviation for a commit
	pin (matching how Norbert already sees short hashes elsewhere, e.g. BaselineOfApptiveBase
	pins FluxBase via the short form itself), the branch name as-is for a branch pin, nothing
	for an unpinned (#none) reference (there is no ref to show)."
	| ref |
	ref := aReference url ref.
	ref ifNil: [ ^ '' ].
	^ (aReference pinKind = #commit and: [ ref size > 7 ])
		ifTrue: [ ref copyFrom: 1 to: 7 ]
		ifFalse: [ ref ]
]

{ #category : 'Protocol (Protocol (Protocol (Protocol (building) - 5 selector(s)) - 2 selector(s)) - 2 selector(s)) - 2 selector(s)' }
GftGraphBuilder class >> renderGraph: aGraph projects: projectsToShow onSelect: aOneArgBlock on: canvas [
	"Populates the given RSCanvas with the nodes/edges for projectsToShow (see the sibling
	#canvasFor:projects:onSelect: for the full node/edge styling contract). Split out so the
	GUI can drive SpRoassalPresenter through its script: block -- that presenter rebuilds a fresh
	canvas on every #refresh and repopulates it via the script, so handing it a pre-built canvas
	via #canvas: does not survive a refresh. Answers the canvas."
	| boxes shownNames layout |
	shownNames := projectsToShow collect: [ :p | p name ].
	boxes := projectsToShow
		collect: [ :proj |
			| composite hasOwnStale hasParseError redBorder |
			hasParseError := aGraph hasParseFailure: proj name.
			hasOwnStale := (aGraph staleOutgoingReferencesOf: proj name) isNotEmpty.
			redBorder := hasParseError or: [ hasOwnStale ].
			composite := RSComposite new.
			composite add: (RSBox new
				extent: 130 @ 40;
				color: (self colorFor: proj name usingGraph: aGraph);
				border: (RSBorder new
					color: (redBorder ifTrue: [ Color red ] ifFalse: [ Color black ]);
					width: (redBorder ifTrue: [ 3 ] ifFalse: [ 1 ]);
					yourself);
				yourself).
			composite add: (RSLabel new
				text: proj name;
				color: Color black;
				yourself).
			composite adjustToChildren.
			composite model: proj.
			composite
				when: RSMouseClick
				do: [ :evt | aOneArgBlock value: proj ]
				for: self.
			self addContextMenuTo: composite project: proj graph: aGraph.
			composite ]
		as: RSGroup.
	canvas addAll: boxes.
	(aGraph allReferences reject: [ :r |
		r isExternal or: [
			(shownNames includes: r ownerProjectName) not
				or: [ (shownNames includes: r targetProject name) not ] ] ])
		do: [ :r |
			| builder createdEdges labelText |
			builder := RSEdgeBuilder arrowedLine
				canvas: canvas;
				withBorderAttachPoint;
				color: (self colorForReference: r);
				moveBehind;
				yourself.
			(self displayKeyFor: r) = #branch ifTrue: [ builder dashed ].
			createdEdges := builder useAssociations: { (GftProject named: r ownerProjectName) -> r targetProject }.
			labelText := self edgeLabelTextFor: r.
			labelText isEmpty ifFalse: [
				createdEdges do: [ :edge |
					edge markerMid: (RSLabel new
						text: labelText;
						color: (self colorForReference: r);
						fontSize: 8;
						yourself) ] ] ].
	layout := RSSugiyamaLayout new.
	layout horizontalGap: 50.
	layout verticalGap: 70.
	layout on: canvas nodes.
	canvas @ RSCanvasController.
	^ canvas
]

{ #category : 'building' }
GftGraphBuilder class >> showDiffForReference: aReference [
	"Opens a GftDiffPresenter: a list of changed methods/classes on the left, and the
	old/new source of the selected one in two side-by-side panes on the right."
	| newRef |
	newRef := GftVersionResolver effectiveTipFor: aReference targetProject.
	newRef ifNil: [
		^ UIManager default inform: 'Kein bekannter aktueller Commit für ', aReference targetProject name, ' -- erst Refresh drücken.' ].
	GftDiffPresenter
		openForProject: aReference targetProject
		oldRef: aReference url ref
		newRef: newRef
]
