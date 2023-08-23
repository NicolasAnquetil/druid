Class {
	#name : #FCFGFASTPharoMethod,
	#superclass : #DRMethod,
	#category : #'FAST-CFG-Pharo'
}

{ #category : #accessing }
FCFGFASTPharoMethod >> argumentNames [
	^self codeNode parameters collect: #name
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
FCFGFASTPharoMethod >> temporaryNames [
	^self codeNode localVariables collect: #name
]
