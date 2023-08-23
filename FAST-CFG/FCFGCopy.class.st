Class {
	#name : #FCFGCopy,
	#superclass : #DRCopy,
	#category : #'FAST-CFG-model'
}

{ #category : #testing }
FCFGCopy >> isMandatoryInstruction [ 

	self result isPhysicalRegister ifTrue: [ ^ true ].
	^ false
]
