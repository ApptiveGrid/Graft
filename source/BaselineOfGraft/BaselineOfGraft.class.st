Class {
	#name : 'BaselineOfGraft',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfGraft',
	#package : 'BaselineOfGraft'
}

{ #category : 'baselines' }
BaselineOfGraft >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			package: 'Graft-Core' with: [ spec requires: #() ];
			package: 'Graft-Core-Tests' with: [ spec requires: #('Graft-Core') ];
			package: 'Graft-UI' with: [ spec requires: #('Graft-Core') ].
		spec
			group: 'Core' with: #('Graft-Core' 'Graft-Core-Tests');
			group: 'UI' with: #('Core' 'Graft-UI');
			group: 'default' with: #('UI') ]
]
