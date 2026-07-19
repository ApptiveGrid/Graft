Class {
	#name : 'RSBaselineRewriter',
	#superclass : 'Object',
	#category : 'Releaser-Core',
	#package : 'Releaser-Core'
}

{ #category : 'previewing' }
RSBaselineRewriter class >> previewFor: aBumpStep [
	aBumpStep isConcrete ifFalse: [
		^ self error: 'Cannot render a text preview for a non-concrete (pending) step -- its new ref is not known yet, see RSBumpStep>>isConcrete.' ].
	^ self previewForReference: aBumpStep reference newRef: aBumpStep newRef
]

{ #category : 'previewing' }
RSBaselineRewriter class >> previewForReference: aReference newRef: aNewRef [
	"Text-only preview (never compiles/mutates the live class, see Releaser decisions):
	finds every instance method of the reference's owning BaselineOf class whose source
	literally contains the old pinned ref, and proposes replacing it with aNewRef. A full
	git commit SHA is specific enough that a plain substring search reliably finds the real
	declaration site, including indirections through a helper accessor method (e.g.
	BaselineOfApptiveBase>>commonCommitHash) -- see Releaser doc for the researched pattern."
	| class oldRef matches |
	class := (RSProject named: aReference ownerProjectName) baselineClass.
	oldRef := aReference url ref.
	matches := OrderedCollection new.
	class selectors do: [ :sel |
		| src |
		src := class sourceCodeAt: sel.
		(src includesSubstring: oldRef) ifTrue: [
			matches add: sel -> (src copyReplaceAll: oldRef with: aNewRef) ] ].
	^ RSRewritePreview reference: aReference oldRef: oldRef newRef: aNewRef matches: matches
]
