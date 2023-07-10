Class {
	#name : #DRFASTPharoGeneratorVisitor,
	#superclass : #FASTPharoVisitor,
	#instVars : [
		'druidGenerator'
	],
	#category : #'Druid-FAST-Pharo'
}

{ #category : #accessing }
DRFASTPharoGeneratorVisitor >> druidGenerator [

	^ druidGenerator
]

{ #category : #accessing }
DRFASTPharoGeneratorVisitor >> druidGenerator: anObject [

	druidGenerator := anObject
]

{ #category : #visiting }
DRFASTPharoGeneratorVisitor >> visitFASTTLiteral: aFASTTLiteralNode [
	druidGenerator visitLiteralValueNode: aFASTTLiteralNode
]

{ #category : #visiting }
DRFASTPharoGeneratorVisitor >> visitFASTTStatement: aFASTTStatementNode [

		druidGenerator popOperand.
]

{ #category : #visiting }
DRFASTPharoGeneratorVisitor >> visitFASTTStatementBlock: aFASTTStatementBlockNode [
	"druidGenerator visitBlockNode: aFASTTStatementBlockNode."
	aFASTTStatementBlockNode statements do: [ :each |
		self flag: 'assert: self topFrame operandStack isEmpty'.
		each acceptVisitor: self.
		druidGenerator popOperand.
		self flag: 'assert: self topFrame operandStack isEmpty'.
		"each isReturn ifTrue: [ ^ self ]"
	]

]

{ #category : #visiting }
DRFASTPharoGeneratorVisitor >> visitPharoMethodEntity: aFASTPharoMethodNode [
	super visitPharoMethodEntity: aFASTPharoMethodNode.

	"aFASTJavaMethodNode statementBlock statements do: [ :each |
		self flag: 'assert: self topFrame operandStack isEmpty'.
		each acceptVisitor: self.
		self popOperand.
		self flag: 'assert: self topFrame operandStack isEmpty'.
		each isReturn ifTrue: [ ^ self ] ]."

	"self flag: 'assert: self topFrame operandStack isEmpty'."
	"If the method has no return statement, it should return default value"
	"self pushOperand: self topFrame returnValue.
	self addDeferredReturnState: {
			executionState copy.
			(self addFrameReturn: self topFrame) }"
]
