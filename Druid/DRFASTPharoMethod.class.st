Class {
	#name : #DRFASTPharoMethod,
	#superclass : #DRMethod,
	#category : #'Druid-FAST-Pharo'
}

{ #category : #accessing }
DRFASTPharoMethod >> argumentNames [
	^self codeNode parameters collect: #name
]

{ #category : #execution }
DRFASTPharoMethod >> executeOn: aDRFASTPharoIRGenerator [

	| fastPharoVisitor |
	fastPharoVisitor := DRFASTPharoVisitor new.
	fastPharoVisitor druidGenerator: aDRFASTPharoIRGenerator.
	aDRFASTPharoIRGenerator fastVisitor: fastPharoVisitor.
	self codeNode accept: fastPharoVisitor
]

{ #category : #accessing }
DRFASTPharoMethod >> temporaryNames [
	^self codeNode localVariables collect: #name
]
