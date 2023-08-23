"
Overriding DRMEssageSend >> opcode to allow prettyprinting
"
Class {
	#name : #FCFGMessageSend,
	#superclass : #DRMessageSend,
	#category : #'FAST-CFG-model'
}

{ #category : #testing }
FCFGMessageSend >> isMandatoryInstruction [

	^ true
]

{ #category : #printing }
FCFGMessageSend >> opcode [

	^ '#' , self selector name , ' '
]
