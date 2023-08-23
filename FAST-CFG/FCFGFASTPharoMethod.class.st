Class {
	#name : #FCFGFASTPharoMethod,
	#superclass : #FCFGCode,
	#instVars : [
		'methodNode'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGFASTPharoMethod class >> methodNode: aMethodNode [

	^ self new
		methodNode: aMethodNode;
		yourself
]

{ #category : #accessing }
FCFGFASTPharoMethod >> argumentNames [
	^self codeNode parameters collect: #name
]

{ #category : #activation }
FCFGFASTPharoMethod >> basicNewFrame [

	^ DRStackFrame new
]

{ #category : #accessing }
FCFGFASTPharoMethod >> codeNode [
	
	^ self methodNode
]

{ #category : #activation }
FCFGFASTPharoMethod >> defaultReturnValue: receiver [

	receiver isInstruction ifTrue: [ ^ receiver ].
	^ FCFGInterpreterValue value: receiver
]

{ #category : #execution }
FCFGFASTPharoMethod >> executeOn: aDRFASTPharoIRGenerator [

	| fastPharoVisitor |
	fastPharoVisitor := FCFGFASTPharoVisitor new.
	fastPharoVisitor druidGenerator: aDRFASTPharoIRGenerator.
	aDRFASTPharoIRGenerator fastVisitor: fastPharoVisitor.
	self codeNode accept: fastPharoVisitor
]

{ #category : #accessing }
FCFGFASTPharoMethod >> methodNode [

	^ methodNode
]

{ #category : #accessing }
FCFGFASTPharoMethod >> methodNode: anObject [

	methodNode := anObject
]

{ #category : #printing }
FCFGFASTPharoMethod >> opcode [
	
	^ methodNode selector 
]

{ #category : #accessing }
FCFGFASTPharoMethod >> temporaryNames [
	^self codeNode localVariables collect: #name
]
