"
Overriding DRMEssageSend >> opcode to allow prettyprinting
"
Class {
	#name : #FCFGMessageSend,
	#superclass : #FCFGInstruction,
	#instVars : [
		'methodNode',
		'irGenerator',
		'typeSystem'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGMessageSend >> irGenerator: anIrGenerator [ 

	irGenerator := anIrGenerator
]

{ #category : #testing }
FCFGMessageSend >> isMandatoryInstruction [

	^ true
]

{ #category : #accessing }
FCFGMessageSend >> methodNode [

	^ methodNode
]

{ #category : #accessing }
FCFGMessageSend >> methodNode: anObject [

	methodNode := anObject
]

{ #category : #printing }
FCFGMessageSend >> opcode [

	^ '#' , self selector name , ' '
]

{ #category : #accessing }
FCFGMessageSend >> selector [

	^ self originAST selector
]

{ #category : #accessing }
FCFGMessageSend >> typeSystem [

	^ typeSystem
]

{ #category : #accessing }
FCFGMessageSend >> typeSystem: anObject [

	typeSystem := anObject
]
