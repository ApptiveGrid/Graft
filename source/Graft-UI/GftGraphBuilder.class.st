Class {
	#name : 'GftGraphBuilder',
	#superclass : 'Object',
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'building' }
GftGraphBuilder class >> canvasFor: aGraph onSelect: aOneArgBlock [
	"Builds a Roassal canvas visualizing aGraph: one box per known project (GftProject).
	Fill color via GftDependencyGraph>>statusOf: (orange = own outgoing pins stale, light green =
	up to date, light gray = neutral/no commit-pinned outgoing deps). Border highlights whether
	OTHER projects depend on this one and are behind it (GftDependencyGraph>>hasStaleDependents:) --
	a thick blue border means 'this project has a newer commit that some dependent hasn't picked
	up yet'. Edges styled by pin kind (commit = solid black/orange if stale, branch = dashed gray,
	none = dotted light gray), routed behind the nodes and with generous layer/sibling spacing so
	arrows between non-adjacent layers don't run through unrelated boxes (Sugiyama's own default
	gaps are only 3px/20px, far too tight for 130x40 boxes -- verified 2026-07-19 this was the
	actual cause of Norbert reporting arrows being hard to follow). External/third-party leaves are
	not drawn as nodes -- they are only visible via the detail panel for a selected project, see
	GftPresenter. aOneArgBlock is evaluated with the clicked GftProject."

	| canvas boxes knownToKnownRefs edgesByKind layout |
	canvas := RSCanvas new.
	boxes := aGraph projects
		         collect: [ :proj |
				         | composite hasStaleDependents |
				         hasStaleDependents := aGraph hasStaleDependents:
					                               proj name.
				         composite := RSComposite new.
				         composite add: (RSBox new
						          extent: 130 @ 40;
						          color: (self colorFor: proj name usingGraph: aGraph);
						          border: (RSBorder new
								           color: (hasStaleDependents
										            ifTrue: [ Color blue ]
										            ifFalse: [ Color black ]);
								           width: (hasStaleDependents
										            ifTrue: [ 3 ]
										            ifFalse: [ 1 ]);
								           yourself);
						          yourself).
				         composite add: (RSLabel new
						          text: proj name;
						          color: Color black;
						          yourself).
				         RSVerticalLineLayout new
					         alignCenter;
					         on: composite shapes.
				         composite adjustToChildren.
				         composite model: proj.
				         composite
					         when: RSMouseClick
					         do: [ :evt | aOneArgBlock value: proj ]
					         for: self.
				         composite ]
		         as: RSGroup.
	canvas addAll: boxes.
	knownToKnownRefs := aGraph allReferences reject: [ :r | r isExternal ].
	edgesByKind := Dictionary new.
	knownToKnownRefs do: [ :r |
			(edgesByKind at: r pinKind ifAbsentPut: [ OrderedCollection new ])
				add: r ].
	#( #commit #branch #none ) do: [ :kind |
			| refsOfKind assocs builder |
			refsOfKind := edgesByKind at: kind ifAbsent: [ #(  ) ].
			refsOfKind isEmpty ifFalse: [
					assocs := refsOfKind collect: [ :r |
						          (GftProject named: r ownerProjectName)
						          -> r targetProject ].
					builder := RSEdgeBuilder arrowedLine
						           canvas: canvas;
						           withBorderAttachPoint;
						           color: (self colorForPinKind: kind);
						           moveBehind;
						           yourself.
					kind = #branch ifTrue: [ builder dashed ].
					builder useAssociations: assocs ] ].
	layout := RSSugiyamaLayout new.
	layout horizontalGap: 50.
	layout verticalGap: 70.
	layout on: canvas nodes.
	canvas @ RSCanvasController.
	^ canvas
]

{ #category : 'colors' }
GftGraphBuilder class >> colorFor: aProjectName usingGraph: aGraph [
	(aGraph statusOf: aProjectName) caseOf: {
		[ #stale ] -> [ ^ Color orange ].
		[ #upToDate ] -> [ ^ Color lightGreen ].
		[ #neutral ] -> [ ^ Color veryLightGray ] }
]

{ #category : 'colors' }
GftGraphBuilder class >> colorForPinKind: aSymbol [
	aSymbol caseOf: {
		[ #commit ] -> [ ^ Color black ].
		[ #branch ] -> [ ^ Color gray ].
		[ #none ] -> [ ^ Color veryLightGray darker ] }
]
