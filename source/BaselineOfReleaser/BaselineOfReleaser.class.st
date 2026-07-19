Class {
	#name : 'BaselineOfReleaser',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfReleaser',
	#package : 'BaselineOfReleaser'
}

{ #category : 'baselines' }
BaselineOfReleaser >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			package: 'Releaser-Core' with: [ spec requires: #() ];
			package: 'Releaser-Core-Tests' with: [ spec requires: #('Releaser-Core') ];
			package: 'Releaser-UI' with: [ spec requires: #('Releaser-Core') ].
		spec
			group: 'Core' with: #('Releaser-Core' 'Releaser-Core-Tests');
			group: 'UI' with: #('Core' 'Releaser-UI');
			group: 'default' with: #('UI') ]
]
