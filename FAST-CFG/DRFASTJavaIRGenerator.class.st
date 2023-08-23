Class {
	#name : #DRFASTJavaIRGenerator,
	#superclass : #DRMethodIRGenerator,
	#instVars : [
		'fastJavaVisitor'
	],
	#category : #'FAST-CFG-Java'
}

{ #category : #accessing }
DRFASTJavaIRGenerator >> fastJavaVisitor [

	^ fastJavaVisitor
]

{ #category : #accessing }
DRFASTJavaIRGenerator >> fastJavaVisitor: anObject [

	fastJavaVisitor := anObject
]

{ #category : #'frame-access' }
DRFASTJavaIRGenerator >> popOperand [
	self topFrame operandStack
		ifEmpty: [ Transcript show: 'DRFASTJavaIRGenerator popOperand on empty stack' ]
		ifNotEmpty: [ super popOperand ]
]

{ #category : #visiting }
DRFASTJavaIRGenerator >> visitFASTJavaAssignmentExpression: aFASTJavaAssignmentExpressionNode [
 1halt.
	variableSpecialCases at: aFASTJavaAssignmentExpressionNode variable name ifPresent: [ :mapping | 
		| rawMapping |
		rawMapping := mapping allButLast: 'With:' size.
		^ self perform: (rawMapping , 'AssignmentWith:') asSymbol withArguments: { aFASTJavaAssignmentExpressionNode } ].

	self interpretAssignmentNode: aFASTJavaAssignmentExpressionNode
	
]

{ #category : #visiting }
DRFASTJavaIRGenerator >> visitFASTJavaReturnStatement: aFASTJavaReturnStatementNode [
	"adapted from DRIRGenerator>>#visitReturnNode:"

	| value homeFrame fork |

	value := self visitOperand: aFASTJavaReturnStatementNode expression.
	
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
