Class {
	#name : 'GftDependencyGraph',
	#superclass : 'Object',
	#instVars : [
		'referencesByOwner'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'instance creation' }
GftDependencyGraph class >> build [
	"Parses the BaselineOf class of every known project (RSProject knownProjects) and
	builds the full dependency graph across the tracked ApptiveGrid-owned scope."
	^ self new build; yourself
]

{ #category : 'accessing' }
GftDependencyGraph >> allReferences [
	^ referencesByOwner values inject: OrderedCollection new into: [ :acc :each | acc addAll: each; yourself ]
]

{ #category : 'building' }
GftDependencyGraph >> build [
	referencesByOwner := Dictionary new.
	GftProject knownProjects do: [ :project |
		referencesByOwner at: project name put: (GftBaselineParser referencesFor: project) ]
]

{ #category : 'accessing' }
GftDependencyGraph >> dependentsOf: aProjectName [
	"All references (from any known project) that point at aProjectName -- i.e. the edges
	Graft would need to walk to cascade a new commit of aProjectName upward."
	^ self allReferences select: [ :r |
		r targetProject notNil and: [ r targetProject name = aProjectName ] ]
]

{ #category : 'accessing' }
GftDependencyGraph >> externalReferences [
	"References that point outside the tracked ApptiveGrid-owned scope (third-party leaves)."
	^ self allReferences select: [ :r | r isExternal ]
]

{ #category : 'testing' }
GftDependencyGraph >> hasStaleDependents: aProjectName [
	^ (self staleDependentsOf: aProjectName) isNotEmpty
]

{ #category : 'accessing' }
GftDependencyGraph >> projects [
	^ GftProject knownProjects
]

{ #category : 'accessing' }
GftDependencyGraph >> referencesFrom: aProjectName [
	"All outgoing dependency references declared by the project named aProjectName."
	^ referencesByOwner at: aProjectName ifAbsent: [ #() ]
]

{ #category : 'accessing' }
GftDependencyGraph >> staleDependentsOf: aProjectName [
	"Commit-pinned dependents of aProjectName whose pin is behind aProjectName's current tip --
	i.e. the projects that would need a BaselineOf edit if aProjectName just got a new commit."
	^ (self dependentsOf: aProjectName) select: [ :r | r isStale ]
]

{ #category : 'accessing' }
GftDependencyGraph >> staleOutgoingReferencesOf: aProjectName [
	"aProjectName's own outgoing references that are behind -- what Update would fix for this project."
	^ (self referencesFrom: aProjectName) select: [ :r | r isStale ]
]

{ #category : 'accessing' }
GftDependencyGraph >> staleReferences [
	"All commit-pinned references across the whole graph whose pin is behind the
	target's current tracked-ref tip. Uses only already-fetched local knowledge --
	call RSVersionResolver fetchAll: first (e.g. via the GUI refresh action) to update it."
	^ self allReferences select: [ :r | r isStale ]
]

{ #category : 'accessing' }
GftDependencyGraph >> statusOf: aProjectName [
	"#stale: at least one outgoing commit-pinned reference is behind the target's tip.
	#upToDate: has outgoing commit-pinned reference(s), all current.
	#neutral: no commit-pinned outgoing references at all (a pure leaf w.r.t. cascade purposes)."
	| refs commitRefs |
	refs := self referencesFrom: aProjectName.
	commitRefs := refs select: [ :r | r pinKind = #commit ].
	commitRefs isEmpty ifTrue: [ ^ #neutral ].
	(commitRefs anySatisfy: [ :r | r isStale ]) ifTrue: [ ^ #stale ].
	^ #upToDate
]
