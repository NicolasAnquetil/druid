"
This is part of DRFASTPharoGenerator (that inherits from DRIRMethodGenerator), but it inherits from FASTPharoVisitor
"
Class {
	#name : #DRFASTPharoVisitor,
	#superclass : #FASTPharoVisitor,
	#instVars : [
		'druidGenerator',
		'specialCases'
	],
	#category : #'Druid-FAST-Pharo'
}

{ #category : #accessing }
DRFASTPharoVisitor >> druidGenerator [

	^ druidGenerator
]

{ #category : #accessing }
DRFASTPharoVisitor >> druidGenerator: anObject [

	druidGenerator := anObject
]

{ #category : #initialization }
DRFASTPharoVisitor >> initialize [
	super initialize.

	specialCases := Dictionary new.
]

{ #category : #visiting }
DRFASTPharoVisitor >> visitFASTReturnStatement: aFASTPharoReturnStatementNode [

	^druidGenerator visitReturnNode: aFASTPharoReturnStatementNode 
]

{ #category : #visiting }
DRFASTPharoVisitor >> visitFASTTLiteral: aFASTTLiteralNode [
	^druidGenerator visitLiteralValueNode: aFASTTLiteralNode
]

{ #category : #visiting }
DRFASTPharoVisitor >> visitFASTTStatementBlock: aFASTTStatementBlockNode [
	^druidGenerator visitBlockNode: aFASTTStatementBlockNode
]

{ #category : #visiting }
DRFASTPharoVisitor >> visitFASTVariableExpression: aFASTVariableExpression [
	"possible actions
	- visitArgumentVariableNode:
	- visitClassVariableNode:
	- visitGlobalVariableNode:
	- visitInstanceVariableNode:
	- visitLiteralVariableNode:
	- visitLocalVariableNode:
	- visitSelfNode:
	- visitSuperNode:
	- visitTemporaryVariableNode:
	- visitThisContextNode:
	- visitVariableNode:
	
	For now will always assume a 'generic variable'
	"

	^ druidGenerator visitVariableNode: aFASTVariableExpression
]

{ #category : #visiting }
DRFASTPharoVisitor >> visitPharoMessageSend: aPharoMessageSend [

	^druidGenerator visitMessageNode: aPharoMessageSend
]

{ #category : #visiting }
DRFASTPharoVisitor >> visitPharoMethodEntity: aPharoMethodEntity [
	^druidGenerator visitMethodNode: aPharoMethodEntity
]
