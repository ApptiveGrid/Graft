Class {
	#name : 'GftProjectTest',
	#superclass : 'TestCase',
	#instVars : [
		'savedSelection'
	],
	#category : 'Graft-Core-Tests',
	#package : 'Graft-Core-Tests'
}

{ #category : 'running' }
GftProjectTest >> setUp [
	super setUp.
	savedSelection := GftProject selectedProjectNames.
	GftProject clearSelection.
	GftProject flushImageProjects
]

{ #category : 'running' }
GftProjectTest >> tearDown [
	savedSelection isEmpty
		ifTrue: [ GftProject clearSelection ]
		ifFalse: [ GftProject selectedProjectNames: savedSelection ].
	GftProject flushImageProjects.
	super tearDown
]

{ #category : 'tests' }
GftProjectTest >> testAllKnownProjectsResolveToALoadedBaselineClass [
	GftProject knownProjects do: [ :p |
		self assert: p baselineClass notNil description: p baselineClassName, ' is not a loaded class (', p name, ')' ]
]

{ #category : 'tests' }
GftProjectTest >> testAllKnownProjectsResolveToARealIceRepository [
	GftProject knownProjects do: [ :p |
		self assert: p iceRepository notNil description: 'no Iceberg repository registered for ', p name ]
]

{ #category : 'tests - selection' }
GftProjectTest >> testClearSelectionRestoresFullScope [
	GftProject selectedProjectNames: #('FluxBase').
	self assert: GftProject managedProjects size equals: 1.
	GftProject clearSelection.
	self assert: GftProject managedProjects size equals: GftProject imageProjects size
]

{ #category : 'tests - selection' }
GftProjectTest >> testDerivedImageProjectsHaveBaselineClassName [
	"Every non-curated image project got its baselineClassName derived from the Iceberg working copy
	(#fromIceRepository:), so it resolves to a BaselineOf* class."
	| curatedNames |
	curatedNames := (GftProject knownProjects collect: [ :p | p name ]) asSet.
	(GftProject imageProjects reject: [ :p | curatedNames includes: p name ]) do: [ :p |
		self assert: (p baselineClassName beginsWith: 'BaselineOf')
			description: p name, ' -> ', p baselineClassName printString ]
]

{ #category : 'tests - selection' }
GftProjectTest >> testEmptySelectionShowsAllImageProjects [
	GftProject clearSelection.
	self assert: GftProject managedProjects size equals: GftProject imageProjects size
]

{ #category : 'tests - selection' }
GftProjectTest >> testImageProjectsIsSupersetOfKnownProjects [
	| imageNames |
	imageNames := (GftProject imageProjects collect: [ :p | p name ]) asSet.
	GftProject knownProjects do: [ :p |
		self assert: (imageNames includes: p name) description: p name, ' missing from imageProjects' ]
]

{ #category : 'tests' }
GftProjectTest >> testNamedLooksUpByExactName [
	self assert: (GftProject named: 'FluxBase') name equals: 'FluxBase'.
	self assert: (GftProject named: 'does-not-exist') isNil
]

{ #category : 'tests - selection' }
GftProjectTest >> testNamedResolvesImageProjectsBeyondKnown [
	"named: must resolve any image project, not just the curated ones -- this is what lets a freshly
	cloned repo be picked and shown without a code edit."
	GftProject imageProjects do: [ :p |
		self assert: (GftProject named: p name) name equals: p name ]
]

{ #category : 'tests' }
GftProjectTest >> testProjectForOwnerRepoAnswersNilForThirdPartyRepo [
	"A repo that is not present in the image universe (not cloned) resolves to nil -- an external
	leaf. NeoCSV etc. used to qualify but are now cloned image projects, so use a name that is
	definitely absent, keeping the test meaningful regardless of what is checked out."
	self assert: (GftProject projectForOwner: 'no-such-owner' repo: 'no-such-repo-xyz') isNil
]

{ #category : 'tests' }
GftProjectTest >> testProjectForOwnerRepoResolvesKnownProject [
	| p |
	p := GftProject projectForOwner: 'ApptiveGrid' repo: 'FluxBase'.
	self assert: p notNil.
	self assert: p name equals: 'FluxBase'
]

{ #category : 'tests - selection' }
GftProjectTest >> testSelectionDefaultsToEmpty [
	self assert: GftProject selectedProjectNames isEmpty.
	self deny: GftProject hasSelection
]

{ #category : 'tests - selection' }
GftProjectTest >> testSelectionFiltersManagedProjects [
	| some |
	some := (GftProject imageProjects first: 3) collect: [ :p | p name ].
	GftProject selectedProjectNames: some.
	self assert: GftProject hasSelection.
	self assert: (GftProject managedProjects collect: [ :p | p name ]) asSet equals: some asSet
]
