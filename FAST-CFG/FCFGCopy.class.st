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

{ #category : #printing }
FCFGCopy >> prettyPrint [
	
	^ result name, ' := ', operands first name asString
]
