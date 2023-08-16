Class {
	#name : #DRFASTPharoIRGenerator,
	#superclass : #Object,
	#instVars : [
		'fastVisitor',
		'controlFlowGraph',
		'specialCases',
		'currentBasicBlock',
		'executionState',
		'numberOfArguments'
	],
	#category : #'Druid-FAST-Pharo'
}

{ #category : #'execution state' }
DRFASTPharoIRGenerator >> addDeferredReturnState: anExecutionState [

	"Record that this execution stack did a method return
	We will merge this one with other returned states when this method finishes"

	^ (self topFrame homeFrameWithState: anExecutionState first) 
		  addDeferredReturnState: anExecutionState
]

{ #category : #'execution state' }
DRFASTPharoIRGenerator >> addFrameReturn: aDRStackFrame [

	self
		addInstructionFrom: aDRStackFrame method
		instructionKind: DRFrameReturn
		operands: { aDRStackFrame returnValue }.
	^ aDRStackFrame returnValue: self popOperand
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> addInstruction: instruction from: aNode [
	 
	instruction origin: thisContext sender stack.
	self currentBasicBlock addInstruction: instruction.
	instruction originAST: aNode.
	self pushOperand: instruction.
	^ instruction
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> addInstructionFrom: aNode instructionKind: instructionClass operands: operands [
	
	| instruction |
	instruction := self
		instantiate: instructionClass
		operands: operands.
	^ self addInstruction: instruction from: aNode
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> addInstructionWithNoResultFrom: aNode instructionKind: instructionClass operands: operands [
	
	| instruction |
	instruction := self
		instantiateNoResultInstruction: instructionClass
		operands: operands.
	^ self addInstruction: instruction from: aNode
]

{ #category : #factory }
DRFASTPharoIRGenerator >> allocateTemporaryRegister [
	
	^ self instructionFactory allocateTemporaryRegister
]

{ #category : #'basic-blocks' }
DRFASTPharoIRGenerator >> basicNewBasicBlock [
	
	^ self basicNewBasicBlockWithState: nil
]

{ #category : #'basic-blocks' }
DRFASTPharoIRGenerator >> basicNewBasicBlockWithState: anExecutionState [

	| block |
	block := controlFlowGraph newBasicBlock.
	block origin: thisContext stack.
	^ block
]

{ #category : #factory }
DRFASTPharoIRGenerator >> createInitialBasicBlock [

	^ self newBasicBlock
]

{ #category : #'basic-blocks' }
DRFASTPharoIRGenerator >> currentBasicBlock [
	^ currentBasicBlock
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> currentOperandStack [

	^ executionState vmOperandStack
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> executionState [
	
	^ executionState
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> executionState: aDRExecutionState [

	executionState := aDRExecutionState
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> fastVisitor [

	^ fastVisitor
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> fastVisitor: anObject [

	fastVisitor := anObject
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> finishCodeInterpretation: lastFrame [

	currentBasicBlock return: lastFrame returnedValue
]

{ #category : #'special cases' }
DRFASTPharoIRGenerator >> ifSpecialMessage: aRBMessageNode then: aBlock [
	^specialCases at: aRBMessageNode selector name ifPresent: aBlock
]

{ #category : #initialization }
DRFASTPharoIRGenerator >> initialBasicBlock [
	
	^ controlFlowGraph initialBasicBlock
]

{ #category : #initialization }
DRFASTPharoIRGenerator >> initialize [

	| initialExecutionState |
	super initialize.
	controlFlowGraph := self newCFG.
	
	specialCases := Dictionary new.
	self initializeSpecialCases.
	
	"Push a top frame"
	initialExecutionState := DRExecutionStack new.
	
	currentBasicBlock := self initialBasicBlock.
	executionState := DRExecutionState new
		vmState: (DRVMState new
			operandStack: Stack new;
			yourself);
		executionStack: initialExecutionState;
		yourself.

]

{ #category : #initialization }
DRFASTPharoIRGenerator >> initializeSpecialCases [

	"Control flow and comparisons"
	specialCases at: #value put: #interpretBlockValueWith:.
	specialCases at: #value: put: #interpretBlockValueWith:.
	specialCases at: #cull: put: #interpretBlockCullWith:.
	specialCases at: #ifTrue: put: #interpretIfTrueWith:.
	specialCases at: #whileTrue: put: #interpretWhileTrueWith:.
	specialCases at: #caseOf:otherwise: put: #interpretCaseOfWith:.

]

{ #category : #factory }
DRFASTPharoIRGenerator >> instantiate: anInstructionClass operands: aCollection [ 
	
	| instruction |
	instruction := anInstructionClass operands: aCollection result: self allocateTemporaryRegister.
	^ instruction
]

{ #category : #factory }
DRFASTPharoIRGenerator >> instantiateNoResultInstruction: anInstructionClass operands: aCollection [ 
	
	| instruction |
	instruction := anInstructionClass operands: aCollection.
	instruction origin: thisContext sender stack.
	instruction result: DRNoRegister new.
	^ instruction
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> instructionFactory [
	^ controlFlowGraph instructionFactory
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

{ #category : #API }
DRFASTPharoIRGenerator >> interpretCode: aDRCode receiver: aReceiver arguments: arguments [

	self pushFrameForCode: aDRCode receiver: aReceiver.

	"Iterate based on the defined arguments.
	In ifNotNil: arguments are optional"
	1 to: aDRCode argumentNames size do: [ :i | | name |
		name := aDRCode argumentNames at: i.
		self topFrame writeTemporaryNamed: name withValue: (arguments at: i).
	].

	aDRCode executeOn: self.
	^ self popFrame.
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> ir [

	^ controlFlowGraph
]

{ #category : #'deferred retruns' }
DRFASTPharoIRGenerator >> mergeDeferredReturns: deferredMethodReturns in: aDRBasicBlock [

	| frameReturns stackFrame |
	self flag: #TODO. "Is it ok to take the first one?"
	stackFrame := deferredMethodReturns values first topFrame.
	currentBasicBlock := aDRBasicBlock.
	frameReturns := deferredMethodReturns keys.
	frameReturns do: [ :frameReturn | 
		(aDRBasicBlock hasPredecessor: frameReturn basicBlock) ifTrue: [ "Remove to keep the order" 
			aDRBasicBlock removePredecessor: frameReturn basicBlock ].
		frameReturn basicBlock jumpTo: aDRBasicBlock ].
	self addInstructionFrom: stackFrame method instructionKind: DRPhiFunction operands: frameReturns.
	stackFrame returnValue: self popOperand.
	^ self addFrameReturn: stackFrame
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

{ #category : #'basic-blocks' }
DRFASTPharoIRGenerator >> newBasicBlock [

	| newBasicBlock |
	newBasicBlock := self basicNewBasicBlock.
	^ currentBasicBlock := newBasicBlock
]

{ #category : #initialization }
DRFASTPharoIRGenerator >> newCFG [
	
	^ DRControlFlowGraph new
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> numberOfArguments [

	^ numberOfArguments
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> numberOfArguments: aValue [ 
	numberOfArguments := aValue.

	0 to: numberOfArguments - 1 do: [ :i |
		self push: (self currentBasicBlock loadArgument: i) ]
]

{ #category : #'pharo-stack' }
DRFASTPharoIRGenerator >> pop [

	self currentOperandStack ifEmpty: [ self error: 'Operand stack underflow!' ].
	^ self currentOperandStack pop
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> popFrame [
	
	| poppedFrame |
	"Here we are in callee"
	poppedFrame := self popFrameMergingDeferredReturns.
	
	"Last frame!"
	executionState executionStack ifEmpty: [
		self finishCodeInterpretation: poppedFrame.
		^ poppedFrame ].
	
	"Here we are in caller"
	self pushOperand: poppedFrame returnValue.	
	
	^ poppedFrame
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> popFrameMergingDeferredReturns [

	self resolveDeferredMethodReturns: self topFrame.
	^ executionState popFrame
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> popOperand [

	^ self topFrame pop
]

{ #category : #'pharo-stack' }
DRFASTPharoIRGenerator >> push: aValue [
	
	"Update the operand stack to keep track of the new position"
	^ self executionState pushVM: aValue
]

{ #category : #'stack management' }
DRFASTPharoIRGenerator >> pushFrame: aDruidStackFrame [ 
	
	executionState pushFrame: aDruidStackFrame
]

{ #category : #'stack management' }
DRFASTPharoIRGenerator >> pushFrameForCode: aDRCode receiver: aReceiver [

	^ aDRCode pushFrameIn: self receiver: aReceiver
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> pushOperand: anOperand [

	self topFrame push: anOperand
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> receiver [
	
	^ self topFrame receiver
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> receiver: aDRValue [

	self push: aDRValue
]

{ #category : #'deferred returns' }
DRFASTPharoIRGenerator >> resolveDeferredMethodReturns: aDRFrame [

	| mirrorFrame newFrameReturn deferredReturnsBlock pieces deferredFrameReturn newReturn |
	aDRFrame deferredMethodReturns ifEmpty: [ ^ self ].
	mirrorFrame := aDRFrame mirrorFrame.

	"If there were returns attached to popped frame, merge all of them in a single state. If there was only one return this is important also to override implicit returns"

	mirrorFrame poppedValue ifNil: [ "There are no provious returns"
		self assert: aDRFrame exitBasicBlock isEmptyBasicBlock.
		newFrameReturn := self mergeDeferredReturns: aDRFrame deferredMethodReturns in: aDRFrame exitBasicBlock.
		mirrorFrame poppedValue: newFrameReturn. "Save it in a secure and common place"
		aDRFrame clearDeferredMethodReturns.
		^ self ].

	"There is a previous return, we have to integrate new ones"

	self assert: aDRFrame returnValue isFrameReturn not.
	self assert: mirrorFrame poppedValue isNotNil.

	deferredReturnsBlock := self newBasicBlock.
	deferredFrameReturn := self mergeDeferredReturns: aDRFrame deferredMethodReturns in: deferredReturnsBlock.
	pieces := mirrorFrame poppedValue breakBasicBlock.

	"Update exitBasicBlock and continue from there"
	aDRFrame exitBasicBlock: pieces last.
	self currentBasicBlock: aDRFrame exitBasicBlock.

	deferredReturnsBlock jumpTo: aDRFrame exitBasicBlock.
	newReturn := aDRFrame exitBasicBlock addInstruction: (self instructionFactory phiWithVariables: {  }).
	aDRFrame returnValue: newReturn.
	newFrameReturn := self addFrameReturn: aDRFrame.
	mirrorFrame poppedValue replaceUsesBy: newFrameReturn.
	newReturn operands: { 
			mirrorFrame poppedValue.
			deferredFrameReturn }.
	mirrorFrame poppedValue: (newFrameReturn).
	aDRFrame clearDeferredMethodReturns
]

{ #category : #'frame-access' }
DRFASTPharoIRGenerator >> temporaryAt: aString [ 
	
	^ self topFrame temporaryAt: aString withState: executionState
]

{ #category : #accessing }
DRFASTPharoIRGenerator >> topFrame [

	^ executionState topFrame
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitArgumentVariableNode: aRBVariableNode [ 
	
	^ self visitTemporaryVariableNode: aRBVariableNode 
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitAssignmentNode: aRBAssignmentNode [

	"variableSpecialCases at: aRBAssignmentNode variable name ifPresent: [ :mapping | 
		| rawMapping |
		rawMapping := mapping allButLast: 'With:' size.
		^ self perform: (rawMapping , 'AssignmentWith:') asSymbol withArguments: { aRBAssignmentNode } ]."

	self interpretAssignmentNode: aRBAssignmentNode
	
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
DRFASTPharoIRGenerator >> visitMethodNode: aRBMethodNode [

	(aRBMethodNode hasPragmaNamed: #druidExitPoint) ifTrue: [
		| failure primitiveReturn returnState |
		failure := self currentBasicBlock copy: 1.
		self currentPrimitiveFailureCode: failure.

		returnState := executionState copy.
		primitiveReturn := returnState baseFrame.
		primitiveReturn push: DRNullValue new. "Return something"

		"Record that this execution stack did a method return
		We will merge this one with other returned states when this method finishes"
		primitiveReturn addDeferredReturnState: {
				returnState.
				(self addFrameReturn: primitiveReturn) }.

		"If the method has no return statement, it should still return something"
		^ self ].

	(aRBMethodNode hasPragmaNamed: #druidJITCompileTimeExpression)
		ifTrue: [
			| copy |
			"Only support single return statements for now"
			self assert: aRBMethodNode statements size = 1.
			self assert: aRBMethodNode statements first isReturn.
			copy := self currentBasicBlock copy:
				        (DRJitCompileTimeExpression expression:
					         aRBMethodNode statements first value formattedCode).
			self topFrame returnValue: copy.
			self addDeferredReturnState: {
					executionState copy.
					(self addFrameReturn: self topFrame) }.
			^ self ].

	aRBMethodNode statements do: [ :each |
		self assert: self topFrame operandStack isEmpty.
		each acceptVisitor: self.
		self popOperand.
		self assert: self topFrame operandStack isEmpty.
		each isReturn ifTrue: [ ^ self ] ].

	self assert: self topFrame operandStack isEmpty.
	"If the method has no return statement, it should return default value"
	self pushOperand: self topFrame returnValue.
	self addDeferredReturnState: {
			executionState copy.
			(self addFrameReturn: self topFrame) }
]

{ #category : #'special-cases' }
DRFASTPharoIRGenerator >> visitOperand: aDRValue [

	aDRValue acceptVisitor: self.
	^ self popOperand
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
DRFASTPharoIRGenerator >> visitTemporaryVariableNode: aRBVariableNode [ 
	
	| value |
	value := self temporaryAt: aRBVariableNode name.

	value isNullValue ifTrue: [ "If Null then it is a method local variable"
		^ self
			  addInstructionFrom: aRBVariableNode
			  instructionKind: DRLoadTemporaryVariable
			  operands: { aRBVariableNode name asDRValue } ].

	"Else, it is an argument"
	^ self pushOperand: value
]

{ #category : #visiting }
DRFASTPharoIRGenerator >> visitVariableNode: aFASTVariableExpression [
	"a generic visit method for unspecified variables"

	^self pushOperand: aFASTVariableExpression asDRValue
]
