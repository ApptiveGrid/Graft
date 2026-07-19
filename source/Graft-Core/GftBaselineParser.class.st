Class {
	#name : 'GftBaselineParser',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'parsing' }
GftBaselineParser class >> referencesFor: aProject [
	"Answers an OrderedCollection of RSDependencyReference for every project/baseline
	dependency declared by aProject's BaselineOf class. Works by asking Metacello to
	build the (fully evaluated -- concatenations and helper-method indirections like
	commonCommitHash already resolved) version spec, rather than re-parsing source,
	so it is robust to however the repository: string was assembled in the baseline."
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
	^ metacelloProjectSpecs
		select: [ :p | p hasRepository ]
		thenCollect: [ :p |
			| repoUrl |
			repoUrl := GftRepositoryUrl parse: p repositorySpecs first description.
			GftDependencyReference
				ownerProjectName: aProject name
				declaredName: p name
				url: repoUrl ]
]
