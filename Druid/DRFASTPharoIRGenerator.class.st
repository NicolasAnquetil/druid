Class {
	#name : #DRFASTPharoIRGenerator,
	#superclass : #DRMethodIRGenerator,
	#instVars : [
		'fastPharoVisitor'
	],
	#category : #'Druid-FAST-Pharo'
}

{ #category : #accessing }
DRFASTPharoIRGenerator >> fastPharoVisitor [

	^ fastPharoVisitor
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> fastPharoVisitor: anObject [

	fastPharoVisitor := anObject
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> popOperand [
	self topFrame operandStack
		ifEmpty: [ Transcript show: 'DRFASTPharoIRGenerator popOperand on empty stack' ]
		ifNotEmpty: [ super popOperand ]
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitPharoAssignmentExpression: aFASTPharoAssignmentExpressionNode [
 1halt.
	variableSpecialCases at: aFASTPharoAssignmentExpressionNode variable name ifPresent: [ :mapping | 
		| rawMapping |
		rawMapping := mapping allButLast: 'With:' size.
		^ self perform: (rawMapping , 'AssignmentWith:') asSymbol withArguments: { aFASTPharoAssignmentExpressionNode } ].

	self interpretAssignmentNode: aFASTPharoAssignmentExpressionNode
	
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitPharoReturnStatement: aFASTPharoReturnStatementNode [
	"adapted from DRIRGenerator>>#visitReturnNode:"

	| value homeFrame fork |

	value := self visitOperand: aFASTPharoReturnStatementNode expression.
	
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
