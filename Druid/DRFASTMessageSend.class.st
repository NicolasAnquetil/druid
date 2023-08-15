"
Overriding DRMEssageSend >> opcode to allow prettyprinting
"
Class {
	#name : #DRFASTMessageSend,
	#superclass : #DRMessageSend,
	#category : #'Druid-FAST-Pharo'
}

{ #category : #printing }
DRFASTMessageSend >> opcode [

	^ '#' , self selector name , ' '
]
