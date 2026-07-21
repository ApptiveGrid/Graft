Class {
	#name : 'GftDiffFormatter',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'formatting' }
GftDiffFormatter class >> collectChangeLines: aNode into: lines [
	aNode value hasChanges ifTrue: [
		lines add: aNode value class name , ': ', ((aNode allPathSegments collect: [ :s | s asString ]) fold: [ :a :b | a, '>>', b ]) ].
	aNode children do: [ :child | self collectChangeLines: child into: lines ]
]

{ #category : 'formatting' }
GftDiffFormatter class >> textDiffFor: aProject oldRef: oldRef newRef: newRef [
	"A readable summary of what changed in aProjects own repository between two commits --
	one class/method-level line per real change (added/removed/modified), using Icebergs own
	diff engine (IceDiff). Not a full source-level diff, but enough to see at a glance what a
	dependent has not picked up yet. Answers a message instead of raising if either ref cannot
	be resolved in the local repository (e.g. an old ref that was force-pushed away)."
	| repo oldCommit newCommit diff lines |
	repo := aProject iceRepository.
	repo ifNil: [ ^ 'Kein Iceberg-Repository für ', aProject name, '.' ].
	oldCommit := [ repo lookupCommit: oldRef ] on: Error do: [ :e | nil ].
	newCommit := [ repo lookupCommit: newRef ] on: Error do: [ :e | nil ].
	(oldCommit isNil or: [ oldCommit isUnknownCommit ]) ifTrue: [
		^ 'Alter Commit ', oldRef, ' ist lokal nicht bekannt -- ggf. erst Refresh drücken.' ].
	(newCommit isNil or: [ newCommit isUnknownCommit ]) ifTrue: [
		^ 'Neuer Commit ', newRef, ' ist lokal nicht bekannt -- ggf. erst Refresh drücken.' ].
	diff := IceDiff from: oldCommit to: newCommit.
	diff isEmpty ifTrue: [ ^ 'Kein Unterschied zwischen ', oldRef, ' und ', newRef, '.' ].
	lines := OrderedCollection new.
	self collectChangeLines: diff tree into: lines.
	lines isEmpty ifTrue: [ ^ 'Unterschied gefunden, aber keine einzelnen Änderungen extrahierbar (', oldRef, '..', newRef, ').' ].
	^ (OrderedCollection new
		add: 'Änderungen in ', aProject name, ' zwischen ', oldRef, ' und ', newRef, ':';
		addAll: lines;
		yourself) fold: [ :a :b | a, (String with: Character cr), b ]
]
