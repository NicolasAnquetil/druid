Class {
	#name : #FCFGPharoIRGenerator,
	#superclass : #Object,
	#instVars : [
		'fastVisitor',
		'controlFlowGraph',
		'specialCases',
		'currentBasicBlock',
		'executionState',
		'numberOfArguments'
	],
	#category : #'FAST-CFG-Pharo'
}

{ #category : #'execution state' }
FCFGPharoIRGenerator >> addDeferredReturnState: anExecutionState [

	"Record that this execution stack did a method return
	We will merge this one with other returned states when this method finishes"

	^ (self topFrame homeFrameWithState: anExecutionState first) 
		  addDeferredReturnState: anExecutionState
]

{ #category : #'execution state' }
FCFGPharoIRGenerator >> addFrameReturn: aDRStackFrame [

	self
		addInstructionFrom: aDRStackFrame method
		instructionKind: FCFGFrameReturn
		operands: { aDRStackFrame returnValue }.
	^ aDRStackFrame returnValue: self popOperand
]

{ #category : #visiting }
FCFGPharoIRGenerator >> addInstruction: instruction from: aNode [
	 
	instruction origin: thisContext sender stack.
	self currentBasicBlock addInstruction: instruction.
	instruction originAST: aNode.
	self pushOperand: instruction.
	^ instruction
]

{ #category : #visiting }
FCFGPharoIRGenerator >> addInstructionFrom: aNode instructionKind: instructionClass operands: operands [
	
	| instruction |
	instruction := self
		instantiate: instructionClass
		operands: operands.
	^ self addInstruction: instruction from: aNode
]

{ #category : #visiting }
FCFGPharoIRGenerator >> addInstructionWithNoResultFrom: aNode instructionKind: instructionClass operands: operands [
	
	| instruction |
	instruction := self
		instantiateNoResultInstruction: instructionClass
		operands: operands.
	^ self addInstruction: instruction from: aNode
]

{ #category : #factory }
FCFGPharoIRGenerator >> allocateTemporaryRegister [
	
	^ self instructionFactory allocateTemporaryRegister
]

{ #category : #'basic-blocks' }
FCFGPharoIRGenerator >> basicNewBasicBlock [
	
	^ self basicNewBasicBlockWithState: nil
]

{ #category : #'basic-blocks' }
FCFGPharoIRGenerator >> basicNewBasicBlockWithState: anExecutionState [

	| block |
	block := controlFlowGraph newBasicBlock.
	block origin: thisContext stack.
	^ block
]

{ #category : #'ir-generation' }
FCFGPharoIRGenerator >> blockClosureGenerator [

	^ self class new
]

{ #category : #'special-cases' }
FCFGPharoIRGenerator >> branchFrom: startingBasicBlock onEdge: anEdgeBlock doing: aBlockToEvaluate [

	| branchEntryBlock branchExitBlock |	
	branchEntryBlock := self newBasicBlockWithState: nil during: aBlockToEvaluate.
	
	"Then update the successor and predecessor edges"
	anEdgeBlock value: branchEntryBlock.
	branchEntryBlock addPredecessor: startingBasicBlock.
	
	"Get the exit basic block, restore the starting basic block to simplify the caller's interaction"
	branchExitBlock := self currentBasicBlock.
	currentBasicBlock := startingBasicBlock.	
	^ branchExitBlock
]

{ #category : #factory }
FCFGPharoIRGenerator >> createInitialBasicBlock [

	^ self newBasicBlock
]

{ #category : #'basic-blocks' }
FCFGPharoIRGenerator >> currentBasicBlock [
	^ currentBasicBlock
]

{ #category : #'frame-access' }
FCFGPharoIRGenerator >> currentOperandStack [

	^ executionState vmOperandStack
]

{ #category : #accessing }
FCFGPharoIRGenerator >> executionState [
	
	^ executionState
]

{ #category : #accessing }
FCFGPharoIRGenerator >> executionState: aDRExecutionState [

	executionState := aDRExecutionState
]

{ #category : #accessing }
FCFGPharoIRGenerator >> fastVisitor [

	^ fastVisitor
]

{ #category : #accessing }
FCFGPharoIRGenerator >> fastVisitor: anObject [

	fastVisitor := anObject
]

{ #category : #visiting }
FCFGPharoIRGenerator >> finishCodeInterpretation: lastFrame [

	currentBasicBlock return: lastFrame returnedValue
]

{ #category : #'special cases' }
FCFGPharoIRGenerator >> ifSpecialMessage: aRBMessageNode then: aBlock [
	^specialCases at: aRBMessageNode selector name ifPresent: aBlock
]

{ #category : #initialization }
FCFGPharoIRGenerator >> initialBasicBlock [
	
	^ controlFlowGraph initialBasicBlock
]

{ #category : #initialization }
FCFGPharoIRGenerator >> initialize [

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
FCFGPharoIRGenerator >> initializeSpecialCases [

	"Control flow and comparisons"
	specialCases at: #value put: #interpretBlockValueWith:.
	specialCases at: #value: put: #interpretBlockValueWith:.
	specialCases at: #cull: put: #interpretBlockCullWith:.
	specialCases at: #ifTrue: put: #interpretIfTrueWith:.
	specialCases at: #whileTrue: put: #interpretWhileTrueWith:.
	specialCases at: #caseOf:otherwise: put: #interpretCaseOfWith:.

]

{ #category : #inline }
FCFGPharoIRGenerator >> inlineGenerator [

	| newIR |
	newIR := DRMethodIRGeneratorInline new
		         controlFlowGraph: controlFlowGraph;
		         yourself.
	newIR executionState: executionState copy.
	^ newIR
]

{ #category : #factory }
FCFGPharoIRGenerator >> instantiate: anInstructionClass operands: aCollection [ 
	
	| instruction |
	instruction := anInstructionClass operands: aCollection result: self allocateTemporaryRegister.
	^ instruction
]

{ #category : #factory }
FCFGPharoIRGenerator >> instantiateNoResultInstruction: anInstructionClass operands: aCollection [ 
	
	| instruction |
	instruction := anInstructionClass operands: aCollection.
	instruction origin: thisContext sender stack.
	instruction result: FCFGNoRegister new.
	^ instruction
]

{ #category : #accessing }
FCFGPharoIRGenerator >> instructionFactory [
	^ controlFlowGraph instructionFactory
]

{ #category : #interpreting }
FCFGPharoIRGenerator >> interpretAssignmentNode: aRBAssignmentNode [

	| value |
	value := self visitOperand: aRBAssignmentNode expression.

	((aRBAssignmentNode variable famixVariable isAttribute) and: 
	[ aRBAssignmentNode variable famixVariable isClassSide not ]) ifTrue: [ 
		^ self
			  addInstructionWithNoResultFrom: aRBAssignmentNode
			  instructionKind: FCFGStoreInstanceVariable
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
			  instructionKind: FCFGStoreTemporaryVariable
			  operands: { 
					  aRBAssignmentNode variable name asDRValue. "Fix temporary names collisions"
					  value } ].

	self unexplored
]

{ #category : #interpreting }
FCFGPharoIRGenerator >> interpretBlockBody: aRBBlockNode [

	aRBBlockNode statements allButLastDo: [ :e |
		e acceptVisitor: self.
		"If this is a return, exit.
		=> This block returns nothing"
		self popOperand.
		self assert: self topFrame operandStack isEmpty.
		e isReturn ifTrue: [ 
			self pushOperand: FCFGNullValue new.
			self assert: self topFrame operandStack size = 1.
			^ self ] ].
	
	"Evaluate the last statement but do not pop the operand, as it will be the block's value"
	
	"If the block had no statements, it has nil value"
	aRBBlockNode statements ifEmpty: [
		^ self pushOperand: nil asDRValue.
	].

	"Otherwise the block value is the value of its last expression"
	aRBBlockNode statements last acceptVisitor: self.
	self assert: self topFrame operandStack size = 1.
]

{ #category : #API }
FCFGPharoIRGenerator >> interpretCode: aDRCode receiver: aReceiver arguments: arguments [

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

{ #category : #'special - cases' }
FCFGPharoIRGenerator >> interpretIfTrueWith: aRBMessageNode [

	| trueBranchBasicBlockOut conditionalJump startingBasicBlock executionStateBeforeBranch |
	aRBMessageNode receiver acceptVisitor: self.
	conditionalJump := self
		                   instantiateNoResultInstruction: FCFGBranchIfTrue
		                   operands: { self popOperand }.
	conditionalJump originAST: aRBMessageNode.

	self currentBasicBlock endInstruction: conditionalJump.

	self pushOperand: DRNullValue new.
	executionStateBeforeBranch := executionState copy.

	self popOperand.

	trueBranchBasicBlockOut := self
		                           branchFrom: self currentBasicBlock
		                           onEdge: [ :branchEntryBlock | 
		                           conditionalJump trueBranch: branchEntryBlock ]
		                           doing: [ self interpretBlockBody: aRBMessageNode arguments first ].

	"Merge point"
	startingBasicBlock := self currentBasicBlock.
	self newBasicBlock.
	self currentBasicBlock addPredecessor: startingBasicBlock.
	conditionalJump falseBranch: self currentBasicBlock.

	"Could happen that the evaluated block had a non local return.
	In that case, this block should not arrive to this merge point
		=> do not add the jump"
	trueBranchBasicBlockOut hasFinalInstruction
		ifTrue: [ executionState := executionStateBeforeBranch ]
		ifFalse: [
			executionState := DRStackMerger new
				                  builder: self;
				                  mergeBlock: currentBasicBlock;
				                  mergeAll: { executionStateBeforeBranch. executionState copy }.
			trueBranchBasicBlockOut jumpTo: self currentBasicBlock ]
]

{ #category : #accessing }
FCFGPharoIRGenerator >> ir [

	^ controlFlowGraph
]

{ #category : #'deferred retruns' }
FCFGPharoIRGenerator >> mergeDeferredReturns: deferredMethodReturns in: aDRBasicBlock [

	| frameReturns stackFrame |
	self flag: #TODO. "Is it ok to take the first one?"
	stackFrame := deferredMethodReturns values first topFrame.
	currentBasicBlock := aDRBasicBlock.
	frameReturns := deferredMethodReturns keys.
	frameReturns do: [ :frameReturn | 
		(aDRBasicBlock hasPredecessor: frameReturn basicBlock) ifTrue: [ "Remove to keep the order" 
			aDRBasicBlock removePredecessor: frameReturn basicBlock ].
		frameReturn basicBlock jumpTo: aDRBasicBlock ].
	self addInstructionFrom: stackFrame method instructionKind: FCFGPhiFunction operands: frameReturns.
	stackFrame returnValue: self popOperand.
	^ self addFrameReturn: stackFrame
]

{ #category : #visiting }
FCFGPharoIRGenerator >> messageSendInstructionFor: aRBMessageNode receiver: receiver arguments: arguments method: method [
	"Instantiating a DRFASTMessageSend instead of a DRMessageSend"
	
	| instruction |
	instruction := self
		               instantiate: FCFGMessageSend
		               operands: { receiver } , arguments.

	instruction irGenerator: self inlineGenerator.
	instruction typeSystem: self typeSystem.
	instruction methodNode: (method ifNotNil: [ method ast ]).
	^ self addInstruction: instruction from: aRBMessageNode
]

{ #category : #'basic-blocks' }
FCFGPharoIRGenerator >> newBasicBlock [

	| newBasicBlock |
	newBasicBlock := self basicNewBasicBlock.
	^ currentBasicBlock := newBasicBlock
]

{ #category : #'basic-blocks' }
FCFGPharoIRGenerator >> newBasicBlockWithState: anExecutionState [

	| newBasicBlock |
	newBasicBlock := self basicNewBasicBlockWithState: anExecutionState.
	^ currentBasicBlock := newBasicBlock
]

{ #category : #'basic-blocks' }
FCFGPharoIRGenerator >> newBasicBlockWithState: execState during: aFullBlockClosure [ 
	
	| inBasicBlock |
	inBasicBlock := self newBasicBlockWithState: execState.
	aFullBlockClosure value.
	^ inBasicBlock
]

{ #category : #initialization }
FCFGPharoIRGenerator >> newCFG [
	
	^FCFGControlFlowGraph new
]

{ #category : #'execution state' }
FCFGPharoIRGenerator >> newVMState [
	
	^ DRVMState new
		initializeOnBuilder: self;
		yourself
]

{ #category : #accessing }
FCFGPharoIRGenerator >> numberOfArguments [

	^ numberOfArguments
]

{ #category : #accessing }
FCFGPharoIRGenerator >> numberOfArguments: aValue [ 
	numberOfArguments := aValue.

	0 to: numberOfArguments - 1 do: [ :i |
		self push: (self currentBasicBlock loadArgument: i) ]
]

{ #category : #'pharo-stack' }
FCFGPharoIRGenerator >> pop [

	self currentOperandStack ifEmpty: [ self error: 'Operand stack underflow!' ].
	^ self currentOperandStack pop
]

{ #category : #'frame-access' }
FCFGPharoIRGenerator >> popFrame [
	
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
FCFGPharoIRGenerator >> popFrameMergingDeferredReturns [

	self resolveDeferredMethodReturns: self topFrame.
	^ executionState popFrame
]

{ #category : #'frame-access' }
FCFGPharoIRGenerator >> popOperand [

	^ self topFrame pop
]

{ #category : #'pharo-stack' }
FCFGPharoIRGenerator >> push: aValue [
	
	"Update the operand stack to keep track of the new position"
	^ self executionState pushVM: aValue
]

{ #category : #'stack management' }
FCFGPharoIRGenerator >> pushFrame: aDruidStackFrame [ 
	
	executionState pushFrame: aDruidStackFrame
]

{ #category : #'stack management' }
FCFGPharoIRGenerator >> pushFrameForCode: aDRCode receiver: aReceiver [

	^ aDRCode pushFrameIn: self receiver: aReceiver
]

{ #category : #'frame-access' }
FCFGPharoIRGenerator >> pushOperand: anOperand [

	self topFrame push: anOperand
]

{ #category : #'frame-access' }
FCFGPharoIRGenerator >> receiver [
	
	^ self topFrame receiver
]

{ #category : #'frame-access' }
FCFGPharoIRGenerator >> receiver: aDRValue [

	self push: aDRValue
]

{ #category : #'deferred returns' }
FCFGPharoIRGenerator >> resolveDeferredMethodReturns: aDRFrame [

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

{ #category : #visiting }
FCFGPharoIRGenerator >> resolveMessageSend: aRBMessageNode receiver: receiver [

	| arguments |
	arguments := aRBMessageNode arguments collect: [ :e | 
		             e acceptVisitor: self.
		             self popOperand ].

	self
		resolveMessageSend: aRBMessageNode
		receiver: receiver
		arguments: arguments
]

{ #category : #visiting }
FCFGPharoIRGenerator >> resolveMessageSend: aRBMessageNode receiver: receiver arguments: arguments [

	^ self
		  messageSendInstructionFor: aRBMessageNode
		  receiver: receiver
		  arguments: arguments
		  method: nil "Infer methods with a Type System"
]

{ #category : #'frame-access' }
FCFGPharoIRGenerator >> temporaryAt: aString [ 
	
	^ self topFrame temporaryAt: aString withState: executionState
]

{ #category : #accessing }
FCFGPharoIRGenerator >> topFrame [

	^ executionState topFrame
]

{ #category : #accessing }
FCFGPharoIRGenerator >> typeSystem [

	^ DRPragmaBasedTypeSystem new
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitArgumentVariableNode: aRBVariableNode [ 
	
	^ self visitTemporaryVariableNode: aRBVariableNode 
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitAssignmentNode: aRBAssignmentNode [

	"variableSpecialCases at: aRBAssignmentNode variable name ifPresent: [ :mapping | 
		| rawMapping |
		rawMapping := mapping allButLast: 'With:' size.
		^ self perform: (rawMapping , 'AssignmentWith:') asSymbol withArguments: { aRBAssignmentNode } ]."

	self interpretAssignmentNode: aRBAssignmentNode
	
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitBlockNode: aRBBlockNode [

	self pushOperand: (DRBlockClosure new
			 blockNode: aRBBlockNode;
			 irGenerator: self blockClosureGenerator;
			 outerContext: self topFrame;
			 yourself)
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitInstanceVariableNode: aFASTPharoVariableNode [

	self
		addInstructionFrom: aFASTPharoVariableNode
		instructionKind: FCFGLoadInstanceVariable
		operands: { 
				self topFrame receiver.
				aFASTPharoVariableNode famixVariable asDRValue }
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitLiteralValueNode: aRBLiteralValueNode [

	self
		addInstructionFrom: aRBLiteralValueNode
		instructionKind: FCFGCopy
		operands: { (FCFGConstantValue value: aRBLiteralValueNode value) }
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitMessageNode: aRBMessageNode [

	| receiver |
	self ifSpecialMessage: aRBMessageNode then: [ :mapping | 
		^ self perform: mapping withArguments: { aRBMessageNode } ].

	"Resolve it as a normal send"
	aRBMessageNode receiver acceptVisitor: self.
	receiver := self popOperand.
	self resolveMessageSend: aRBMessageNode receiver: receiver
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitMethodNode: aRBMethodNode [

	(aRBMethodNode hasPragmaNamed: #druidExitPoint) ifTrue: [
		| failure primitiveReturn returnState |
		failure := self currentBasicBlock copy: 1.
		self currentPrimitiveFailureCode: failure.

		returnState := executionState copy.
		primitiveReturn := returnState baseFrame.
		primitiveReturn push: FCFGNullValue new. "Return something"

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
FCFGPharoIRGenerator >> visitOperand: aDRValue [

	aDRValue acceptVisitor: self.
	^ self popOperand
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitReturnNode: aRBReturnNode [

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
	self pushOperand: FCFGNullValue new
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitTemporaryVariableNode: aRBVariableNode [ 
	
	| value |
	value := self temporaryAt: aRBVariableNode name.

	value isNullValue ifTrue: [ "If Null then it is a method local variable"
		^ self
			  addInstructionFrom: aRBVariableNode
			  instructionKind: FCFGLoadTemporaryVariable
			  operands: { aRBVariableNode name asDRValue } ].

	"Else, it is an argument"
	^ self pushOperand: value
]

{ #category : #visiting }
FCFGPharoIRGenerator >> visitVariableNode: aFASTVariableExpression [
	"a generic visit method for unspecified variables"

	^self pushOperand: aFASTVariableExpression asDRValue
]
