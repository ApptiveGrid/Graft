Class {
	#name : 'GftProject',
	#superclass : 'Object',
	#instVars : [
		'name',
		'host',
		'owner',
		'baselineClassName',
		'trackedRef'
	],
	#classVars : [
		'KnownProjects'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'known projects' }
GftProject class >> buildKnownProjects [
	"ApptiveGrid-owned projects only (v1 scope, decided with Norbert 2026-07-19) -- third-party
	dependencies (NeoCSV, Zinc, Mustache, ...) are deliberately not tracked as bump targets here,
	they only ever appear as external leaves in the dependency graph. Owner/host verified against
	the actual git remotes registered in Iceberg; trackedRef is the conventional release branch per
	project (verified via Iceberg remote branches where possible, see Graft doc)."
	^ {
		self name: 'apptive-base' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveBase' trackedRef: 'development'.
		self name: 'apptive-account' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveAccount' trackedRef: 'master'.
		self name: 'apptive-common' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveCommon' trackedRef: 'main'.
		self name: 'apptive-scheduler' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveScheduler' trackedRef: 'main'.
		self name: 'apptivescript' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveScript' trackedRef: 'master'.
		self name: 'FluxBase' host: #github owner: 'ApptiveGrid' baselineClassName: 'BaselineOfFluxBase' trackedRef: 'main'.
		self name: 'Soil' host: #github owner: 'ApptiveGrid' baselineClassName: 'BaselineOfSoil' trackedRef: 'main'.
		self name: 'Canopy' host: #github owner: 'ApptiveGrid' baselineClassName: 'BaselineOfCanopy' trackedRef: 'main'.
		self name: 'HOP' host: #github owner: 'ApptiveGrid' baselineClassName: 'BaselineOfHOP' trackedRef: 'main'.
		self name: 'JSONSchema' host: #github owner: 'zweidenker' baselineClassName: 'BaselineOfJSONSchema' trackedRef: 'master'.
		self name: 'Rhizome' host: #github owner: 'ApptiveGrid' baselineClassName: 'BaselineOfRhizome' trackedRef: 'main'.
		self name: 'Gossip' host: #github owner: 'ApptiveGrid' baselineClassName: 'BaselineOfGossip' trackedRef: 'main'.
		self name: 'PharoDEVS' host: #github owner: 'ApptiveGrid' baselineClassName: 'BaselineOfPharoDEVS' trackedRef: 'main'.
	}
]

{ #category : 'known projects' }
GftProject class >> knownProjects [
	"Cached registry of all ApptiveGrid-owned projects Graft v1 manages. See #buildKnownProjects."
	^ KnownProjects ifNil: [ KnownProjects := self buildKnownProjects ]
]

{ #category : 'instance creation' }
GftProject class >> name: aName host: aHostSymbol owner: anOwner baselineClassName: aClassName trackedRef: aRef [
	^ self new
		setName: aName host: aHostSymbol owner: anOwner baselineClassName: aClassName trackedRef: aRef;
		yourself
]

{ #category : 'known projects' }
GftProject class >> named: aName [
	^ self named: aName ifAbsent: [ nil ]
]

{ #category : 'known projects' }
GftProject class >> named: aName ifAbsent: aBlock [
	^ self knownProjects detect: [ :p | p name = aName ] ifNone: aBlock
]

{ #category : 'known projects' }
GftProject class >> projectForOwner: anOwner repo: aRepoName [
	"Resolves an owner+repo pair (as parsed from a repository: URL) back to a known project,
	or nil if it points outside the tracked ApptiveGrid-owned scope (a third-party leaf)."
	^ self knownProjects
		detect: [ :p | (p owner sameAs: anOwner) and: [ p name sameAs: aRepoName ] ]
		ifNone: [ nil ]
]

{ #category : 'known projects' }
GftProject class >> resetKnownProjects [
	"Testing/dev hook: force a rebuild of the known-projects registry."
	KnownProjects := nil
]

{ #category : 'comparing' }
GftProject >> = anObject [
	^ (anObject isKindOf: GftProject) and: [ name = anObject name ]
]

{ #category : 'accessing' }
GftProject >> baselineClass [
	"Resolves the loaded BaselineOf class for this project, or nil if not currently loaded in the image."
	^ Smalltalk at: baselineClassName asSymbol ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GftProject >> baselineClassName [
	^ baselineClassName
]

{ #category : 'comparing' }
GftProject >> hash [
	^ name hash
]

{ #category : 'accessing' }
GftProject >> host [
	^ host
]

{ #category : 'accessing' }
GftProject >> iceRepository [
	"Resolves the Iceberg repository registered for this project, or nil if not registered/checked out."
	^ IceRepository registry detect: [ :r | r name = name ] ifNone: [ nil ]
]

{ #category : 'accessing' }
GftProject >> name [
	^ name
]

{ #category : 'accessing' }
GftProject >> owner [
	^ owner
]

{ #category : 'printing' }
GftProject >> printOn: aStream [
	aStream nextPutAll: 'RSProject(', name, ')'
]

{ #category : 'private' }
GftProject >> setName: aName host: aHostSymbol owner: anOwner baselineClassName: aClassName trackedRef: aRef [
	name := aName.
	host := aHostSymbol.
	owner := anOwner.
	baselineClassName := aClassName.
	trackedRef := aRef
]

{ #category : 'accessing' }
GftProject >> trackedRef [
	^ trackedRef
]
