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

{ #category : #'special cases' }
DRFASTPharoIRGenerator >> ifSpecialMessage: aRBMessageNode then: aBlock [
	^specialCases at: aRBMessageNode selector name ifPresent: aBlock
]

{ #category : #interpreting }
DRFASTPharoIRGenerator >> interpretAssignmentNode: aRBAssignmentNode [

	| value |
	value := self visitOperand: aRBAssignmentNode expression.

	((aRBAssignmentNode variable famixVariable isAttribute) and: 
	[ aRBAssignmentNode variable famixVariable isClassSide not ]) ifTrue: [ 
		^ self
			  addInstructionWithNoResultFrom: aRBAssignmentNode
			  instructionKind: DRStoreInstanceVariable
			  operands: { 
					  self receiver.
					  aRBAssignmentNode variable famixVariable asDRValue.
					  value } ].

	(aRBAssignmentNode variable famixVariable isLocalVariable) ifTrue: [ 
		self topFrame
				  temporaryAt: aRBAssignmentNode variable name
				  put: value
				  withState: executionState.
		^ self
			  addInstructionWithNoResultFrom: aRBAssignmentNode
			  instructionKind: DRStoreTemporaryVariable
			  operands: { 
					  aRBAssignmentNode variable name asDRValue. "Fix temporary names collisions"
					  value } ].

	self unexplored
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> messageSendInstructionFor: aRBMessageNode receiver: receiver arguments: arguments method: method [
	"Instantiating a DRFASTMessageSend instead of a DRMessageSend"
	
	| instruction |
	instruction := self
		               instantiate: DRFASTMessageSend
		               operands: { receiver } , arguments.

	instruction irGenerator: self inlineGenerator.
	instruction typeSystem: self typeSystem.
	instruction methodNode: (method ifNotNil: [ method ast ]).
	^ self addInstruction: instruction from: aRBMessageNode
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> popOperand [
	self topFrame operandStack
		ifEmpty: [ 'DRFASTPharoIRGenerator popOperand on empty stack' traceCr. ^nil ]
		ifNotEmpty: [ ^super popOperand ]
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitInstanceVariableNode: aFASTPharoVariableNode [

	self
		addInstructionFrom: aFASTPharoVariableNode
		instructionKind: DRLoadInstanceVariable
		operands: { 
				self topFrame receiver.
				aFASTPharoVariableNode famixVariable asDRValue }
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
	"a generic visit method for unspecified variables"

	^self pushOperand: aFASTVariableExpression asDRValue
]
