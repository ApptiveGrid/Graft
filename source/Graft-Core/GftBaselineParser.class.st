Class {
	#name : 'GftBaselineParser',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'Protocol (Protocol (Protocol (Protocol (parsing) - 1 selector(s)) - 1 selector(s)) - 1 selector(s)) - 1 selector(s)' }
GftBaselineParser class >> referencesFor: aProject [
	"Answers an OrderedCollection of GftDependencyReference for every project/baseline
	dependency declared by aProject's BaselineOf class. Works by asking Metacello to
	build the (fully evaluated -- concatenations and helper-method indirections like
	commonCommitHash already resolved) version spec, rather than re-parsing source,
	so it is robust to however the repository: string was assembled in the baseline.
	Dependency specs whose repository description does not parse as a recognised git URL
	(GftRepositoryUrl parse: -> nil) are skipped, so an arbitrary/foreign baseline cannot
	produce a reference with a nil url that later breaks rendering."
	| baselineClass spec metacelloProjectSpecs |
	baselineClass := aProject baselineClass.
	baselineClass ifNil: [
		^ self error: 'Cannot resolve BaselineOf class ', aProject baselineClassName, ' for ', aProject name, ' -- is it loaded in the image?' ].
	spec := baselineClass new project version spec.
	metacelloProjectSpecs := OrderedCollection new.
	spec packageSpecsInLoadOrder do: [ :pkgSpec |
		pkgSpec
			projectDo: [ :p | metacelloProjectSpecs add: p ]
			packageDo: [ :ignored | ]
			groupDo: [ :ignored | ] ].
	^ (metacelloProjectSpecs
		select: [ :p | p hasRepository ]
		thenCollect: [ :p |
			| repoUrl |
			repoUrl := GftRepositoryUrl parse: p repositorySpecs first description.
			repoUrl ifNil: [ nil ] ifNotNil: [
				GftDependencyReference
					ownerProjectName: aProject name
					declaredName: p name
					url: repoUrl ] ])
		reject: [ :r | r isNil ]
]
