Class {
	#name : #FCFGCopy,
	#superclass : #FCFGInstruction,
	#category : #'FAST-CFG-model'
}

{ #category : #testing }
FCFGCopy >> isCopy [ 

	^true 
]

{ #category : #testing }
FCFGCopy >> isMandatoryInstruction [ 

	self result isPhysicalRegister ifTrue: [ ^ true ].
	^ false
]

{ #category : #printing }
FCFGCopy >> opcode [
	
	^ ':='
]
