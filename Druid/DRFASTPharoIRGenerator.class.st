Class {
	#name : #DRFASTPharoIRGenerator,
	#superclass : #DRMethodIRGenerator,
	#instVars : [
		'fastVisitor'
	],
	#category : #'Druid-FAST-Pharo'
}

{ #category : #accessing }
DRFASTPharoIRGenerator >> fastVisitor [

	^ fastVisitor
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> fastVisitor: anObject [

	fastVisitor := anObject
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> popOperand [
	self topFrame operandStack
		ifEmpty: [ 'DRFASTPharoIRGenerator popOperand on empty stack' traceCr. ^nil ]
		ifNotEmpty: [ ^super popOperand ]
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitReturnNode: aRBReturnNode [

	| value homeFrame fork |

	value := self visitOperand: aRBReturnNode expression.
	
	"Create a fork, push value operand and create a FrameReturn to keep DeferredReturnState ready to merge"
	fork := executionState copy.
	homeFrame := fork topFrame homeFrameWithState: fork.
	homeFrame push: value.
	homeFrame returnValue: value.

	self addDeferredReturnState: { 
			fork.
			self addFrameReturn: homeFrame }.

	"The return is a statement with no value"
	self pushOperand: DRNullValue new
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitVariableNode: aFASTVariableExpression [
	^self pushOperand: aFASTVariableExpression asDRValue
]
