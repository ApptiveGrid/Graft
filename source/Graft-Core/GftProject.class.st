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
		'ImageProjectsCache',
		'SelectedProjectNames'
	],
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'known projects' }
GftProject class >> buildKnownProjects [
	"ApptiveGrid-owned projects only (v1 scope, decided with Norbert 2026-07-19) -- third-party
	dependencies (NeoCSV, Zinc, Mustache, ...) are deliberately not tracked as bump targets here,
	they only ever appear as external leaves in the dependency graph. Owner/host verified against
	the actual git remotes registered in Iceberg. trackedRef is a MANUALLY researched/maintained
	guess at each projects conventional release branch -- there is no reliable automatic way to
	derive this: origin/HEAD (a repos actual default-branch pointer) errors out via Icebergs
	libgit2 binding in this image when resolving the symbolic ref, and the locally checked-out
	branch is routinely some unrelated WIP branch, not the tracked one, so it cannot be inferred
	from that either. Norbert corrected apptive-scheduler from main to development 2026-07-21,
	and apptive-account from master to development the same day (Graft had wrongly insisted
	otherwise both times) -- if another entry here is wrong, it needs the same kind of manual fix,
	see Graft doc."
	^ {
		self name: 'apptive-base' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveBase' trackedRef: 'development'.
		self name: 'apptive-account' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveAccount' trackedRef: 'development'.
		self name: 'apptive-common' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveCommon' trackedRef: 'main'.
		self name: 'apptive-scheduler' host: #bitbucket owner: '2denker' baselineClassName: 'BaselineOfApptiveScheduler' trackedRef: 'development'.
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

{ #category : 'Protocol (selection) - 4 selector(s)' }
GftProject class >> clearSelection [
	"Back to the unfiltered default: every image project shows again."
	SelectedProjectNames := nil
]

{ #category : 'Protocol (image projects) - 7 selector(s)' }
GftProject class >> computeImageProjects [
	"Scans the Iceberg registry once and builds the project universe: every registered repo that
	ships a BaselineOf package. A repo whose name matches a curated knownProjects entry reuses that
	entry (keeping its researched trackedRef/host/owner); all others are derived via
	#fromIceRepository:. Repos we cannot interpret are skipped."
	| curatedByName result |
	curatedByName := Dictionary new.
	self knownProjects do: [ :p | curatedByName at: p name put: p ].
	result := OrderedCollection new.
	IceRepository registry do: [ :repo |
		[ | proj |
		  proj := curatedByName at: repo name ifAbsent: [ self fromIceRepository: repo ].
		  proj ifNotNil: [ result add: proj ] ]
		on: Error do: [ :e | ] ].
	^ result
]

{ #category : 'Protocol (image projects) - 7 selector(s)' }
GftProject class >> flushImageProjects [
	"Drops the discovered-projects cache so the next #imageProjects re-scans Iceberg."
	ImageProjectsCache := nil
]

{ #category : 'Protocol (image projects) - 7 selector(s)' }
GftProject class >> fromIceRepository: aRepo [
	"Best-effort GftProject for an Iceberg repo not among the curated knownProjects. The
	BaselineOf* package name becomes baselineClassName (nil -> not a Metacello project, answer nil);
	host/owner are parsed from the first remote (see #parseRemoteUrl:); trackedRef defaults to the
	currently checked-out branch (or main) -- a guess, since the conventional release branch cannot
	be derived reliably (see #buildKnownProjects), good enough to display the project and its
	outgoing dependencies even if staleness stays approximate until corrected. branchName raises
	IceNotInBranch on a detached/branchless checkout, so it is guarded."
	| blPkg host owner parsed ref |
	blPkg := aRepo workingCopy packages detect: [ :p | p name beginsWith: 'BaselineOf' ] ifNone: [ nil ].
	blPkg ifNil: [ ^ nil ].
	host := nil. owner := nil.
	(aRepo remotes ifNil: [ #() ]) ifNotEmpty: [ :rs |
		parsed := self parseRemoteUrl: rs first url.
		host := parsed first. owner := parsed second ].
	ref := ([ aRepo branchName ] on: Error do: [ :e | nil ]) ifNil: [ 'main' ].
	^ self name: aRepo name host: host owner: owner baselineClassName: blPkg name trackedRef: ref
]

{ #category : 'Protocol (selection) - 4 selector(s)' }
GftProject class >> hasSelection [
	^ self selectedProjectNames isNotEmpty
]

{ #category : 'Protocol (image projects) - 7 selector(s)' }
GftProject class >> imageProjects [
	"The project universe (see #computeImageProjects), cached in ImageProjectsCache and flushed by
	#flushImageProjects (start of every GftDependencyGraph build, and on GUI refresh/pick/reset),
	so it never serves a stale registry."
	^ ImageProjectsCache ifNil: [ ImageProjectsCache := self computeImageProjects ]
]

{ #category : 'known projects' }
GftProject class >> knownProjects [
	"Registry of all ApptiveGrid-owned projects Graft v1 manages. See #buildKnownProjects.
	Deliberately uncached (Norbert, 2026-07-21): buildKnownProjects only constructs 13 plain
	value objects, no repo/network access, so caching bought nothing but let a manually
	corrected trackedRef (e.g. apptive-scheduler main->development) silently keep serving
	stale data to a session that had already called this before the fix was loaded."
	^ self buildKnownProjects
]

{ #category : 'Protocol (image projects) - 7 selector(s)' }
GftProject class >> managedProjectNames [
	^ self managedProjects collect: [ :p | p name ]
]

{ #category : 'Protocol (image projects) - 7 selector(s)' }
GftProject class >> managedProjects [
	"The working set Graft shows and graphs: the persisted Custom selection filtered out of the
	image universe, or -- when the selection is empty -- the whole universe. See #selectedProjectNames."
	| sel |
	sel := self selectedProjectNames.
	sel isEmpty ifTrue: [ ^ self imageProjects ].
	^ self imageProjects select: [ :p | sel includes: p name ]
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

{ #category : 'Protocol (known projects) - 5 selector(s)' }
GftProject class >> named: aName ifAbsent: aBlock [
	^ self imageProjects detect: [ :p | p name = aName ] ifNone: aBlock
]

{ #category : 'Protocol (image projects) - 7 selector(s)' }
GftProject class >> parseRemoteUrl: aString [
	"Extracts { hostSymbol. owner } from a git remote URL such as
	git@github.com:owner/repo.git or https://github.com/owner/repo.git. Answers { nil. nil }
	for an unrecognised host."
	| host marker idx rest ownerEnd owner |
	aString ifNil: [ ^ { nil. nil } ].
	host := nil. marker := nil.
	(aString includesSubstring: 'github.com') ifTrue: [ host := #github. marker := 'github.com' ].
	(host isNil and: [ aString includesSubstring: 'bitbucket.org' ])
		ifTrue: [ host := #bitbucket. marker := 'bitbucket.org' ].
	host ifNil: [ ^ { nil. nil } ].
	idx := aString indexOfSubCollection: marker.
	rest := aString copyFrom: idx + marker size to: aString size.
	(rest notEmpty and: [ (rest first = $:) or: [ rest first = $/ ] ]) ifTrue: [ rest := rest allButFirst ].
	ownerEnd := rest indexOf: $/.
	owner := ownerEnd = 0 ifTrue: [ rest ] ifFalse: [ rest copyFrom: 1 to: ownerEnd - 1 ].
	^ { host. owner }
]

{ #category : 'Protocol (known projects) - 5 selector(s)' }
GftProject class >> projectForOwner: anOwner repo: aRepoName [
	"Resolves an owner+repo pair (as parsed from a repository: URL) back to a project in the image
	universe, or nil if it points outside it (a third-party leaf). Owner may be nil on a
	best-effort-derived project, so guard before #sameAs:."
	^ self imageProjects
		detect: [ :p |
			p owner notNil and: [ anOwner notNil
				and: [ (p owner sameAs: anOwner) and: [ p name sameAs: aRepoName ] ] ] ]
		ifNone: [ nil ]
]

{ #category : 'Protocol (selection) - 4 selector(s)' }
GftProject class >> selectedProjectNames [
	"The user-picked subset of project names to show, persisted class-side so it survives image
	restarts and needs no code edit to add/remove a project. Empty = no filter (show every image
	project). Set/cleared via the Custom-picker; see #managedProjects and #selectedProjectNames:."
	^ SelectedProjectNames ifNil: [ #() ]
]

{ #category : 'Protocol (selection) - 4 selector(s)' }
GftProject class >> selectedProjectNames: aCollectionOfNames [
	SelectedProjectNames := aCollectionOfNames asArray
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
