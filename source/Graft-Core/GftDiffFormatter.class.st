Class {
	#name : 'GftDiffFormatter',
	#superclass : 'Object',
	#category : 'Graft-Core',
	#package : 'Graft-Core'
}

{ #category : 'formatting' }
GftDiffFormatter class >> changeNodesFor: aProject oldRef: oldRef newRef: newRef [
	"Answers every IceNode with real changes (added/removed/modified) between the two
	refs, in aProjects own repository -- for a richer, navigable viewer (see GftDiffPresenter)
	than the flat #textDiffFor:oldRef:newRef: summary. Answers an empty collection if the
	repository or either ref cannot be resolved locally."
	| commits diff nodes |
	commits := self resolveCommitsFor: aProject oldRef: oldRef newRef: newRef.
	commits ifNil: [ ^ #() ].
	diff := IceDiff from: commits first to: commits second.
	nodes := OrderedCollection new.
	self collectChangeNodes: diff tree into: nodes.
	^ nodes
]

{ #category : 'formatting' }
GftDiffFormatter class >> collectChangeLines: aNode into: lines [
	aNode value hasChanges ifTrue: [
		lines add: aNode value class name , ': ', ((aNode allPathSegments collect: [ :s | s asString ]) fold: [ :a :b | a, '>>', b ]) ].
	aNode children do: [ :child | self collectChangeLines: child into: lines ]
]

{ #category : 'formatting' }
GftDiffFormatter class >> collectChangeNodes: aNode into: nodes [
	aNode value hasChanges ifTrue: [ nodes add: aNode ].
	aNode children do: [ :child | self collectChangeNodes: child into: nodes ]
]

{ #category : 'formatting' }
GftDiffFormatter class >> labelFor: aNode [
	"+ for content only on the new side, - for content only on the old side, ~ otherwise
	(modified on both sides). Deliberately does not rely on the IceNode operations own
	class (IceAddition/IceRemoval/IceModification) or #isAddition/#isRemoval -- verified
	2026-07-20 that IceAddition/IceRemoval are named from Icebergs internal left/right tree-merge
	perspective, which for a plain #from:to: diff turns out backwards from old/new (IceAddition
	has content on the OLD side only, IceRemoval on the NEW side only) -- comparing the actual
	left/rightContents directly is the only reliable way to label old vs new correctly."
	| op |
	op := aNode value.
	(op leftContents isEmpty and: [ op rightContents isEmpty not ]) ifTrue: [ ^ '+ ' ].
	(op rightContents isEmpty and: [ op leftContents isEmpty not ]) ifTrue: [ ^ '- ' ].
	^ '~ '
]

{ #category : 'formatting' }
GftDiffFormatter class >> pathFor: aNode [
	^ (aNode allPathSegments collect: [ :s | s asString ]) fold: [ :a :b | a, '>>', b ]
]

{ #category : 'formatting' }
GftDiffFormatter class >> resolveCommitsFor: aProject oldRef: oldRef newRef: newRef [
	"Answers an Array {oldCommit. newCommit} resolved against aProjects local Iceberg
	repository, or nil if the repository or either commit cannot be resolved locally."
	| repo oldCommit newCommit |
	repo := aProject iceRepository.
	repo ifNil: [ ^ nil ].
	oldCommit := [ repo lookupCommit: oldRef ] on: Error do: [ :e | nil ].
	newCommit := [ repo lookupCommit: newRef ] on: Error do: [ :e | nil ].
	(oldCommit isNil or: [ oldCommit isUnknownCommit ]) ifTrue: [ ^ nil ].
	(newCommit isNil or: [ newCommit isUnknownCommit ]) ifTrue: [ ^ nil ].
	^ { oldCommit. newCommit }
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
