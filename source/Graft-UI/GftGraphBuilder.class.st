Class {
	#name : 'GftGraphBuilder',
	#superclass : 'Object',
	#category : 'Graft-UI',
	#package : 'Graft-UI'
}

{ #category : 'building' }
GftGraphBuilder class >> canvasFor: aGraph onSelect: aOneArgBlock [
	^ self canvasFor: aGraph projects: aGraph projects onSelect: aOneArgBlock
]

{ #category : 'building' }
GftGraphBuilder class >> canvasFor: aGraph projects: projectsToShow onSelect: aOneArgBlock [
	"Like #canvasFor:onSelect:, but only draws nodes for the projects in projectsToShow (and only
	edges between two shown projects) -- used for the sidebar's 'Alle'/'Custom' filtered views.
	Status/staleness is still computed against the full aGraph, so filtering the view never changes
	what counts as stale. See class comment on #canvasFor:onSelect: for the rest."

	| canvas boxes knownToKnownRefs edgesByKind layout shownNames |
	canvas := RSCanvas new.
	shownNames := projectsToShow collect: [ :p | p name ].
	boxes := projectsToShow
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
	knownToKnownRefs := aGraph allReferences reject: [ :r |
			                    r isExternal or: [
					                    (shownNames includes: r ownerProjectName) not
						                    or: [
						                    (shownNames includes: r targetProject name)
							                    not ] ] ].
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
