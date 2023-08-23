Class {
	#name : #FCFGReturn,
	#superclass : #FCFGInstruction,
	#category : #'FAST-CFG-model'
}

{ #category : #testing }
FCFGReturn >> isMandatoryInstruction [

	^ true
]

{ #category : #printing }
FCFGReturn >> opcode [
	
	^ 'Return'
]
