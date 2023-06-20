Class {
	#name : #DRFASTJavaGeneratorVisitor,
	#superclass : #FASTJavaVisitor,
	#instVars : [
		'druidGenerator'
	],
	#category : #'Druid-FAST'
}

{ #category : #accessing }
DRFASTJavaGeneratorVisitor >> druidGenerator [

	^ druidGenerator
]

{ #category : #accessing }
DRFASTJavaGeneratorVisitor >> druidGenerator: anObject [

	druidGenerator := anObject
]

{ #category : #visiting }
DRFASTJavaGeneratorVisitor >> visitFASTJavaMethodEntity: aFASTJavaMethodNode [
	super visitFASTJavaMethodEntity: aFASTJavaMethodNode.

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

{ #category : #visiting }
DRFASTJavaGeneratorVisitor >> visitFASTJavaVarDeclarator: aFASTJavaVarDeclaratorNode [

	^druidGenerator visitTemporaryVariableNode: aFASTJavaVarDeclaratorNode variable
]

{ #category : #visiting }
DRFASTJavaGeneratorVisitor >> visitFASTTLiteral: aFASTTLiteralNode [
	druidGenerator visitLiteralValueNode: aFASTTLiteralNode
]

{ #category : #visiting }
DRFASTJavaGeneratorVisitor >> visitFASTTStatement: aFASTTStatementNode [

		druidGenerator popOperand.
]

{ #category : #visiting }
DRFASTJavaGeneratorVisitor >> visitFASTTStatementBlock: aFASTTStatementBlockNode [
	"druidGenerator visitBlockNode: aFASTTStatementBlockNode."
	aFASTTStatementBlockNode statements do: [ :each |
		self flag: 'assert: self topFrame operandStack isEmpty'.
		each acceptVisitor: self.
		druidGenerator popOperand.
		self flag: 'assert: self topFrame operandStack isEmpty'.
		"each isReturn ifTrue: [ ^ self ]"
	]

]
