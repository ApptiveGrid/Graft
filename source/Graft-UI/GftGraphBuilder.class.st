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

	| canvas boxes knownToKnownRefs edgesByKey shownNames layout |
	canvas := RSCanvas new.
	shownNames := projectsToShow collect: [ :p | p name ].
	boxes := projectsToShow
		         collect: [ :proj |
				         | composite |
				         composite := RSComposite new.
				         composite add: (RSBox new
						          extent: 130 @ 40;
						          color: (self colorFor: proj name usingGraph: aGraph);
						          border: (RSBorder new
								           color: Color black;
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
	edgesByKey := Dictionary new.
	knownToKnownRefs do: [ :r |
			(edgesByKey
				 at: (self displayKeyFor: r)
				 ifAbsentPut: [ OrderedCollection new ]) add: r ].
	#( #stale #commit #branch #none ) do: [ :key |
			| refsOfKey assocs builder |
			refsOfKey := edgesByKey at: key ifAbsent: [ #(  ) ].
			refsOfKey isEmpty ifFalse: [
					assocs := refsOfKey collect: [ :r |
						          (GftProject named: r ownerProjectName)
						          -> r targetProject ].
					builder := RSEdgeBuilder arrowedLine
						           canvas: canvas;
						           withBorderAttachPoint;
						           color: (self colorForReference: refsOfKey first);
						           moveBehind;
						           yourself.
					key = #branch ifTrue: [ builder dashed ].
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
	"Node fill color is purely about propagation: yellow if this project has shipped something
	that not every dependent has picked up yet (GftDependencyGraph>>hasStaleDependents:), gray
	otherwise -- including leaf/root projects with no dependents at all. Deliberately does not
	reflect whether this project itself needs to pull in an update from ITS OWN dependencies
	(GftDependencyGraph>>statusOf:/staleOutgoingReferencesOf: still answer that; it shows in the
	Veraltete-Pins-Tabelle when the project is selected, just not as a third graph color anymore --
	Norbert simplified this 2026-07-20 to gray/yellow only, one clear question per node: does
	something downstream still need to catch up to me?)."
	^ (aGraph hasStaleDependents: aProjectName)
		ifTrue: [ Color yellow ]
		ifFalse: [ Color veryLightGray ]
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
