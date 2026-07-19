Class {
	#name : 'GftGraphBuilder',
	#superclass : 'Object',
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'building' }
GftGraphBuilder class >> canvasFor: aGraph onSelect: aOneArgBlock [
	"Builds a Roassal canvas visualizing aGraph: one box per known project (GftProject),
	color-coded via GftDependencyGraph>>statusOf:, with one directed edge per reference
	between two known projects, styled by pin kind (commit = solid black/orange if stale,
	branch = dashed gray, none = dotted light gray). External/third-party leaves are not
	drawn as nodes -- they are only visible via the detail panel for a selected project,
	see GftPresenter. aOneArgBlock is evaluated with the clicked GftProject."

	| canvas boxes knownToKnownRefs edgesByKind |
	canvas := RSCanvas new.
	boxes := aGraph projects
		         collect: [ :proj |
				         | composite |
				         composite := RSComposite new.
				         composite add: (RSBox new
						          extent: 130 @ 40;
						          color: (self colorFor: proj name usingGraph: aGraph);
						          border: (RSBorder new color: Color black);
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
						           yourself.
					kind = #branch ifTrue: [ builder dashed ].
					builder useAssociations: assocs ] ].
	RSSugiyamaLayout new on: canvas nodes.
	canvas @ RSCanvasController.
	^ canvas
]

{ #category : 'colors' }
GftGraphBuilder class >> colorFor: aProjectName usingGraph: aGraph [
	(aGraph statusOf: aProjectName) caseOf: {
		[ #stale ] -> [ ^ Color orange ].
		[ #upToDate ] -> [ ^ Color veryLightGreen darker ].
		[ #neutral ] -> [ ^ Color veryLightGray ] }
]

{ #category : 'colors' }
GftGraphBuilder class >> colorForPinKind: aSymbol [
	aSymbol caseOf: {
		[ #commit ] -> [ ^ Color black ].
		[ #branch ] -> [ ^ Color gray ].
		[ #none ] -> [ ^ Color veryLightGray darker ] }
]
