Class {
	#name : 'RSDependencyGraph',
	#superclass : 'Object',
	#instVars : [
		'referencesByOwner'
	],
	#category : 'Releaser-Core',
	#package : 'Releaser-Core'
}

{ #category : 'instance creation' }
RSDependencyGraph class >> build [
	"Parses the BaselineOf class of every known project (RSProject knownProjects) and
	builds the full dependency graph across the tracked ApptiveGrid-owned scope."
	^ self new build; yourself
]

{ #category : 'accessing' }
RSDependencyGraph >> allReferences [
	^ referencesByOwner values inject: OrderedCollection new into: [ :acc :each | acc addAll: each; yourself ]
]

{ #category : 'building' }
RSDependencyGraph >> build [
	referencesByOwner := Dictionary new.
	RSProject knownProjects do: [ :project |
		referencesByOwner at: project name put: (RSBaselineParser referencesFor: project) ]
]

{ #category : 'accessing' }
RSDependencyGraph >> dependentsOf: aProjectName [
	"All references (from any known project) that point at aProjectName -- i.e. the edges
	Releaser would need to walk to cascade a new commit of aProjectName upward."
	^ self allReferences select: [ :r |
		r targetProject notNil and: [ r targetProject name = aProjectName ] ]
]

{ #category : 'accessing' }
RSDependencyGraph >> externalReferences [
	"References that point outside the tracked ApptiveGrid-owned scope (third-party leaves)."
	^ self allReferences select: [ :r | r isExternal ]
]

{ #category : 'accessing' }
RSDependencyGraph >> projects [
	^ RSProject knownProjects
]

{ #category : 'accessing' }
RSDependencyGraph >> referencesFrom: aProjectName [
	"All outgoing dependency references declared by the project named aProjectName."
	^ referencesByOwner at: aProjectName ifAbsent: [ #() ]
]

{ #category : 'accessing' }
RSDependencyGraph >> staleReferences [
	"All commit-pinned references across the whole graph whose pin is behind the
	target's current tracked-ref tip. Uses only already-fetched local knowledge --
	call RSVersionResolver fetchAll: first (e.g. via the GUI refresh action) to update it."
	^ self allReferences select: [ :r | r isStale ]
]

{ #category : 'accessing' }
RSDependencyGraph >> statusOf: aProjectName [
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
