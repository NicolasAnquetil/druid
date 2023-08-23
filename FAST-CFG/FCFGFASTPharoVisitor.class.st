"
This is part of DRFASTPharoGenerator (that inherits from DRIRMethodGenerator), but it inherits from FASTPharoVisitor
"
Class {
	#name : #FCFGFASTPharoVisitor,
	#superclass : #FASTPharoVisitor,
	#instVars : [
		'druidGenerator',
		'specialCases'
	],
	#category : #'FAST-CFG-Pharo'
}

{ #category : #accessing }
FCFGFASTPharoVisitor >> druidGenerator [

	^ druidGenerator
]

{ #category : #accessing }
FCFGFASTPharoVisitor >> druidGenerator: anObject [

	druidGenerator := anObject
]

{ #category : #initialization }
FCFGFASTPharoVisitor >> initialize [
	super initialize.

	specialCases := Dictionary new.
]

{ #category : #generated }
FCFGFASTPharoVisitor >> visitFASTLiteral: aFASTLiteral [
	^druidGenerator visitLiteralValueNode: aFASTLiteral 
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitFASTReturnStatement: aFASTPharoReturnStatementNode [

	^druidGenerator visitReturnNode: aFASTPharoReturnStatementNode 
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitFASTTLiteral: aFASTTLiteralNode [
	^druidGenerator visitLiteralValueNode: aFASTTLiteralNode
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitFASTTStatementBlock: aFASTTStatementBlockNode [
	^druidGenerator visitBlockNode: aFASTTStatementBlockNode
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitFASTVariableExpression: aFASTVariableExpression [

	^aFASTVariableExpression famixVariable
		ifNil: [ druidGenerator visitVariableNode: aFASTVariableExpression ]
		ifNotNil: [ :famixVariable | famixVariable druid: druidGenerator visit: aFASTVariableExpression ]
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitPharoAssignmentExpression: aPharoAssignmentExpression [

	^druidGenerator visitAssignmentNode: aPharoAssignmentExpression 
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitPharoBlockExpression: aPharoBlockExpression [
	"FASTPharoBlockExpression contains a FASTPharoBlockDefinition"
	^druidGenerator visitBlockNode: aPharoBlockExpression block
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitPharoMessageSend: aPharoMessageSend [
	^druidGenerator visitMessageNode: aPharoMessageSend
]

{ #category : #visiting }
FCFGFASTPharoVisitor >> visitPharoMethodEntity: aPharoMethodEntity [
	^druidGenerator visitMethodNode: aPharoMethodEntity
]
