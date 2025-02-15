Class {
	#name : #DRCogitCodeGenerator,
	#superclass : #Object,
	#instVars : [
		'generatorMethodBuilder',
		'fallthroughBlock',
		'deferredBranches',
		'visitedBlocks',
		'availableJumpIndexes'
	],
	#category : #'Druid-Cogit'
}

{ #category : #helpers }
DRCogitCodeGenerator >> allocateVariable: aDRResult [
	
	^ aDRResult name
]

{ #category : #'jump-management' }
DRCogitCodeGenerator >> assignAvailableJumpIndex [

	^ availableJumpIndexes removeFirst
]

{ #category : #'ir-generation' }
DRCogitCodeGenerator >> buildStatementsForInstruction: anInstruction [ 

	^ anInstruction acceptVisitor: self
]

{ #category : #branching }
DRCogitCodeGenerator >> cogitBranchFromCondition: condition type: aType [

	| branchPrefix |
	branchPrefix := aType isFloatType
		                ifTrue: [ 'JumpFP' ]
		                ifFalse: [ 'Jump' ].

	condition isEqualsThanComparison ifTrue: [ 
		^ aType isFloatType
			  ifTrue: [ branchPrefix , 'Equal:' ]
			  ifFalse: [ branchPrefix , 'Zero:' ] ].

	condition isNotEqualsThanComparison ifTrue: [ 
		^ aType isFloatType
			  ifTrue: [ branchPrefix , 'NotEqual:' ]
			  ifFalse: [ branchPrefix , 'NonZero:' ] ].

	condition isGreaterThanComparison ifTrue: [ 
		^ branchPrefix , 'Greater:' ].

	condition isGreaterOrEqualThanComparison ifTrue: [ 
		^ branchPrefix , 'GreaterOrEqual:' ].

	condition isLessThanComparison ifTrue: [ 
		^ branchPrefix , 'Less:' ].
	
	condition isLessOrEqualThanComparison ifTrue: [ 
		^ branchPrefix , 'LessOrEqual:' ].

	condition isOverflow ifTrue: [ 
		aType isFloatType
			ifTrue: [ self error: 'unsupported: cannot test the mask on a floating point number'  ].
		condition isMultiplyOverflow
			ifTrue: [ ^ branchPrefix , 'MultiplyOverflow:' ].
		^ branchPrefix , 'Overflow:' ].

	condition isNoOverflow ifTrue: [ 
		aType isFloatType
			ifTrue: [ self error: 'unsupported: cannot test the mask on a floating point number'  ].
		condition isNoMultiplyOverflow
			ifTrue: [ ^ branchPrefix , 'MultiplyNoOverflow:' ].
		^ branchPrefix , 'NoOverflow:' ].
	
	condition isTestMask ifTrue: [ 
		aType isFloatType
			ifTrue: [ self error: 'unsupported: cannot test the mask on a floating point number'  ].
		^ branchPrefix , 'NonZero:' ].
	
	condition isNoTestMask ifTrue: [ 
		aType isFloatType
			ifTrue: [ self error: 'unsupported: cannot test the mask on a floating point number'  ].
		^ branchPrefix , 'Zero:' ].

	1 halt
]

{ #category : #'jump-management' }
DRCogitCodeGenerator >> deferBranch: anIndex to: aDRBasicBlock [ 
	
	(deferredBranches at: aDRBasicBlock ifAbsentPut: [ OrderedCollection new ])
		add: anIndex
]

{ #category : #'jump-management' }
DRCogitCodeGenerator >> freeJumpIndex: anIndex [ 
	
	availableJumpIndexes addFirst: anIndex
]

{ #category : #'ir-to-ast' }
DRCogitCodeGenerator >> generateBlockIncomingJumps: aDRBasicBlock [

	| jumpIndexes |
	"If someother block is forward jumping to this block, create a label and wire deferred jumps to it"
	jumpIndexes := deferredBranches
		               at: aDRBasicBlock
		               ifAbsent: [ ^ self ].
	generatorMethodBuilder addStatement: (RBAssignmentNode
			 variable: (RBVariableNode named: 'currentBlock')
			 value:
			 (RBMessageNode receiver: RBVariableNode selfNode selector: #Label)).

	jumpIndexes do: [ :i | 
		| jumpVariableName |
		jumpVariableName := self labelForJump: i.
		generatorMethodBuilder addStatement: (RBMessageNode
				 receiver: (RBVariableNode named: jumpVariableName)
				 selector: #jmpTarget:
				 arguments: { (RBVariableNode named: 'currentBlock') }).

		self freeJumpIndex: i ]
]

{ #category : #'ir-to-ast' }
DRCogitCodeGenerator >> generateCodeForCFG: aDRControlFlowGraph [

	| blocks |
	self generatePreambleForCFG: aDRControlFlowGraph.

	"Sort the blocks"
	blocks := aDRControlFlowGraph reversePostOrderBlocks.

	"Make sure the failure exit block is at the end, so it works as a fallthrough with the following bytecode"
	(blocks includes: aDRControlFlowGraph failureExitBlock) ifTrue: [
		blocks remove: aDRControlFlowGraph failureExitBlock.
		blocks addLast: aDRControlFlowGraph failureExitBlock ].

	blocks withIndexDo: [ :b :i |
		fallthroughBlock := blocks at: i + 1 ifAbsent: nil.
		self preProcessBlock: b.
		b instructionsDo: [ :e | self buildStatementsForInstruction: e ] ].
	
	"Generate the postamble in the fallthrough case"
	self generatePostambleForCFG: aDRControlFlowGraph.

	"Return compiled method status for the compiler"

	generatorMethodBuilder addStatement:
		(RBReturnNode value: self returnNodeForCompiledMethod)
]

{ #category : #visiting }
DRCogitCodeGenerator >> generateCompare: aComparison operands: operands [

	| comparands comparisonToGenerate |
	"Generate comparison instruction. In cogit, if you want to do A < B, you have to generate:
	CMP B A
	JumpLessThan xxx
	Thus, operands are inverted always"
	comparands := operands reversed.
	comparisonToGenerate := aComparison.

	"Cogit RTL only supports constants as the first argument.
	Invert the comparison and the condition if necessary, mostly for greaterThan comparisons)."
	
	comparands second isConstant ifTrue: [ 
		comparisonToGenerate := aComparison reversed.
		comparands := comparands reversed ].

	self
		twoOperandCogitRTL: #Cmp
		operands: comparands
		instruction: aComparison.
	^ comparisonToGenerate
]

{ #category : #visiting }
DRCogitCodeGenerator >> generateJump: jumpKind target: aTarget [

	| jumpStatement jumpVariableName jumpTarget jumpIndex |
	"If the jump target is the next block in the order, do not add any jump to it"
	aTarget = fallthroughBlock ifTrue: [ ^ self ].

	jumpIndex := self assignAvailableJumpIndex.

	(self hasVisitedBlock: aTarget) ifTrue: [ 
		"Backwards branch, the jump target already exists with a label.
		Make the jump point to the already generated target"
		jumpTarget := self labelForBlock: aTarget
	] ifFalse: [
		"Forward branch, the jump target does not yet exist.
		Put a 0 for now to generate `cogit Jump: 0`.
		Defer the branch so it is resolved when the target is created"
		self deferBranch: jumpIndex to: aTarget.
		jumpTarget := 0 asLiteralNode ].
	
	jumpVariableName := self labelForJump: jumpIndex.
	generatorMethodBuilder addVariableNamed: jumpVariableName.

	jumpStatement := RBAssignmentNode
		variable: (RBVariableNode named: jumpVariableName)
		value: (RBMessageNode
			receiver: RBVariableNode selfNode
			selector: jumpKind
			arguments: { jumpTarget }).	
				
	generatorMethodBuilder addStatement: jumpStatement.
	
]

{ #category : #visiting }
DRCogitCodeGenerator >> generateMessage: selector operands: operands [

	generatorMethodBuilder addStatement: (RBMessageNode
			 receiver: RBVariableNode selfNode
			 selector: selector
			 arguments: (operands flatCollect: [ :op | self rtlArgumentsForValue: op ]))
]

{ #category : #'ir-to-ast' }
DRCogitCodeGenerator >> generatePostambleForCFG: aDRControlFlowGraph [

	| addStatement |
	"If we need no spill slots, do nothing"
	aDRControlFlowGraph numberOfSpillSlots = 0 ifTrue: [ ^ self ].

	"Otherwise, increment the stack pointer by N*WordSize where N is the number of required spill slots.
	The first spill slot will be [SP], the second will be [SP+WordSize] and so on."
	addStatement := RBMessageNode
		                receiver: RBVariableNode selfNode
		                selector: #SubCq:R:
		                arguments: {
				                (RBLiteralValueNode value:
					                 aDRControlFlowGraph numberOfSpillSlots * 8). "bytes"
				                (RBVariableNode named: 'SPReg') }.
	generatorMethodBuilder addStatement: addStatement
]

{ #category : #'ir-to-ast' }
DRCogitCodeGenerator >> generatePreambleForCFG: aDRControlFlowGraph [

	| addStatement |
	generatorMethodBuilder addVariableNamed: 'currentBlock'.
	
	"If we need no spill slots, do nothing"
	aDRControlFlowGraph numberOfSpillSlots = 0 ifTrue: [ ^ self ].
	
	"Otherwise, increment the stack pointer by N*WordSize where N is the number of required spill slots.
	The first spill slot will be [SP], the second will be [SP+WordSize] and so on."
	addStatement := RBMessageNode
		receiver: RBVariableNode selfNode
		selector: #AddCq:R:
		arguments: {
			RBLiteralValueNode value: aDRControlFlowGraph numberOfSpillSlots * 8 "bytes".
			RBVariableNode named: 'SPReg'
		}.
	generatorMethodBuilder addStatement: addStatement.
]

{ #category : #'ir-to-ast' }
DRCogitCodeGenerator >> generateTargetASTFromIR: aDRControlFlowGraph methodName: aName [

	generatorMethodBuilder selector: aName.
	self generateCodeForCFG: aDRControlFlowGraph.
	^ generatorMethodBuilder methodNode
]

{ #category : #accessing }
DRCogitCodeGenerator >> generatorMethodBuilder [
	^ generatorMethodBuilder
]

{ #category : #testing }
DRCogitCodeGenerator >> hasVisitedBlock: aDRBasicBlock [ 
	
	^ visitedBlocks includesKey: aDRBasicBlock
]

{ #category : #initialization }
DRCogitCodeGenerator >> initialize [

	super initialize.
	generatorMethodBuilder := DRGeneratorMethodBuilder new.
	deferredBranches := Dictionary new.
	availableJumpIndexes := (1 to: 50) asOrderedCollection.

	visitedBlocks := Dictionary new
]

{ #category : #testing }
DRCogitCodeGenerator >> isLastBasicBlock [
	
	"It's the last if we have no fallthrough basic block"
	^ fallthroughBlock isNil
]

{ #category : #compiling }
DRCogitCodeGenerator >> jitCompileTimeExpression: aDRAdd [ 
	
	^ DRJITCompileTimeExpressionGenerator new visit: aDRAdd
	
]

{ #category : #'jump-management' }
DRCogitCodeGenerator >> labelForBlock: aDRBasicBlock [ 
	
	^ RBVariableNode named: (visitedBlocks at: aDRBasicBlock)
]

{ #category : #'jump-management' }
DRCogitCodeGenerator >> labelForJump: jumpIndex [
	
	^ 'jump', jumpIndex asString
]

{ #category : #visiting }
DRCogitCodeGenerator >> oneOperandCogitRTL: aMnemonic operands: operands instruction: anInstruction [

	generatorMethodBuilder addStatement: (RBMessageNode
			 receiver: RBVariableNode selfNode
			 selector:
				 aMnemonic
				 , (operands first result rtlOperandQualifierForInstruction:
						  anInstruction)
			 arguments: (self rtlArgumentsForValue: operands first))
]

{ #category : #'ir-to-ast' }
DRCogitCodeGenerator >> preProcessBlock: aDRBasicBlock [

	aDRBasicBlock hasIncomingBackjumps ifTrue: [ 
		| blockIdentifier |
		"If this block has incoming backjumps, we need to put a label for it and store it"
		blockIdentifier := 'b' , aDRBasicBlock id asString.
		generatorMethodBuilder addVariableNamed: blockIdentifier.
		generatorMethodBuilder addStatement: (RBAssignmentNode
				 variable: (RBVariableNode named: blockIdentifier)
				 value:
				 (RBMessageNode receiver: RBVariableNode selfNode selector: #Label)).
		visitedBlocks at: aDRBasicBlock put: blockIdentifier ].

	self generateBlockIncomingJumps: aDRBasicBlock
]

{ #category : #registers }
DRCogitCodeGenerator >> registerFor: aValue [

	^ aValue result name
]

{ #category : #'ir-to-ast' }
DRCogitCodeGenerator >> returnNodeForCompiledMethod [

	^ RBVariableNode named: 'CompletePrimitive'
]

{ #category : #visiting }
DRCogitCodeGenerator >> rtlArgumentsForValue: aValue [
	"If it is a spilling stack location, we need to return a pair (offset, baseRegister)"

	aValue isMemoryAddress ifTrue: [
		^ aValue rtlArgumentExpressions: self ].

	"Otherwise just return the expression for the value"
	^ { (self rtlExpressionForValue: aValue) }
]

{ #category : #visiting }
DRCogitCodeGenerator >> rtlExpressionForValue: aValue [

	| constantValue |
	"Interpret the booleans as the bits 0 and 1"
	constantValue := (#( true false ) includes: aValue value)
		                 ifTrue: [ aValue value asBit ]
		                 ifFalse: [ aValue value ].

	"Interpret nil as zero"
	constantValue isNil ifTrue: [ constantValue := 0 ].

	constantValue isInteger ifTrue: [ 
		^ constantValue <= 5000
			ifTrue: [ RBLiteralValueNode value: constantValue ]
			ifFalse: [ RBLiteralValueNode new
			  value: constantValue
			  start: 0
			  stop: -1
			  source: constantValue hex ] ].

	^ RBVariableNode named: (self registerFor: aValue)
]

{ #category : #'as yet unclassified' }
DRCogitCodeGenerator >> selectorCogitRTL: aMnemonic operands: operands instruction: anInstruction [

	^ aMnemonic ,
	  ('' join:
		   (operands collect: [ :op | op result rtlOperandQualifierForInstruction: anInstruction ]))
]

{ #category : #visiting }
DRCogitCodeGenerator >> threeOperandCogitRTL: aMnemonic instruction: instruction [

	(instruction operand1 isConstant and: [ 
		 instruction operand2 isConstant not ]) ifTrue: [ 
		^ self
			  threeOperandCogitRTL: aMnemonic
			  instruction: instruction reversed ].

	self verifyAllocationIn2AC: instruction.

	^ self
		  twoOperandCogitRTL: aMnemonic
		  operands: { 
				  instruction operand2.
				  instruction operand1 }
		  instruction: instruction
]

{ #category : #visiting }
DRCogitCodeGenerator >> twoOperandCogitRTL: aMnemonic operands: operands instruction: anInstruction [

	self
		generateMessage: (self selectorCogitRTL: aMnemonic operands: operands instruction: anInstruction)
		operands: operands
]

{ #category : #visiting }
DRCogitCodeGenerator >> twoOperandMoveCogitRTL: anInstruction operands: operands [

	self twoOperandCogitRTL: #Move operands: operands instruction: anInstruction
]

{ #category : #verification }
DRCogitCodeGenerator >> verifyAllocationIn2AC: instruction [

	| allocatedOperands |
	allocatedOperands := (instruction operands collect: [ :op | 
		                      op result ]) asSet.
	instruction result isNoResult ifFalse: [ 
		allocatedOperands add: instruction result ].
	allocatedOperands size > 2 ifTrue: [ 
		self error: 'Cannot write instruction with more than 2 operands: '
			, instruction asString ]
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitAddition: aDRCogitAdd [ 

	^ self threeOperandCogitRTL: #Add instruction: aDRCogitAdd 
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitAnd: aDRAnd [

	^ self threeOperandCogitRTL: #And instruction: aDRAnd
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitBitAnd: aDRCogitBitAnd [ 

	^ self threeOperandCogitRTL: #And instruction: aDRCogitBitAnd

]

{ #category : #visiting }
DRCogitCodeGenerator >> visitBitOr: aDRCogitBitAnd [ 

	^ self threeOperandCogitRTL: #Or instruction: aDRCogitBitAnd

]

{ #category : #visiting }
DRCogitCodeGenerator >> visitBitXor: aDRCogitBitXor [ 

	^ self threeOperandCogitRTL: #Xor instruction: aDRCogitBitXor

]

{ #category : #visiting }
DRCogitCodeGenerator >> visitBranchIfCondition: aDRConditionalJump [
	"Delegate the condition generation to the condition itself.
	It may be a Cmp, a Test or no instruction at all."

	| replacement |
	replacement := aDRConditionalJump condition
		               acceptVisitor: self
		               withBranch: aDRConditionalJump.

	"Generate both jumps, the fallthorugh will get ignored"
	self
		generateJump: (self
				 cogitBranchFromCondition: replacement condition
				 type: replacement operand1 type)
		target: replacement trueBranch.
	self
		generateJump: (self
				 cogitBranchFromCondition: replacement condition negated
				 type: replacement operand1 type)
		target: replacement falseBranch
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitClosureActivation: aDRClosureActivation [

	self threeOperandCogitRTL: #Add instruction: aDRClosureActivation.

	self
		oneOperandCogitRTL: #Jump
		operands: aDRClosureActivation operands
		instruction: aDRClosureActivation
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitComparison: aComparison [

	"Generate comparison instruction. In cogit, if you want to do A < B, you have to generate:
	CMP B A
	JumpLessThan xxx
	Thus, operands are inverted always"
	self
		twoOperandCogitRTL: #Cmp
		operands: aComparison operands reversed
		instruction: aComparison.

	^ aComparison
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitCopy: aDRMove [

	"Do not generate moves of null values"
	| moveOperands |
	aDRMove operands first isNullValue
		ifTrue: [ ^ self ].
	
	moveOperands := { aDRMove operand1. aDRMove result }.
	
	"Do not generate redundant moves (e.g., r0 := r0)"
	(moveOperands collect: [ :e | e result ] as: Set) size = 1
		ifTrue: [ ^ self ].
	
	self twoOperandMoveCogitRTL: aDRMove operands: moveOperands
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitDivision: aDRCogitDivision [

	aDRCogitDivision type isFloatType ifTrue: [
		^ self threeOperandCogitRTL: #Div instruction: aDRCogitDivision
	].

	"Cogit integer division is not in 2AC but in 4AC.
	The (cogit specific) register allocator should inserts a register for REM destination implicitly yet unused.
	It should also put all operands in registers as the cogit instruction does not support constants."


	^ generatorMethodBuilder addStatement: (RBMessageNode
			   receiver: RBVariableNode selfNode
			   selector: #DivR:R:Quo:Rem:
			   arguments: { 
					   (self rtlExpressionForValue: aDRCogitDivision operands second).
					   (self rtlExpressionForValue: aDRCogitDivision operands first).
					   (self rtlExpressionForValue: aDRCogitDivision result).
					   (self rtlExpressionForValue: aDRCogitDivision operands third) })
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitEqualsThan: aDRGreaterThanComparison inBranch: aDRBranchIfCondition [ 
	
	^ self visitComparison: aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitFloatToIntConversion: aDRFloatToInt [

	^ self
		  twoOperandCogitRTL: #Convert
		  operands: { 
				  aDRFloatToInt operand1.
				  aDRFloatToInt result }
		  instruction: aDRFloatToInt
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitGetConditionCode: aDRGetConditionCode [ 
	
	"Generate the code of the form
		CMP
		JMP.COND true:
		RESULT := 0
		JUMP next:
	true:
		RESULT := 1
	next:
	"
	
	"Generate CMP; Jump.COND true; RESULT := 0; JUMP next"
	| comparisonToGenerate branch |
	comparisonToGenerate := self visitComparison: aDRGetConditionCode.
	generatorMethodBuilder addVariableNamed: 'jumpTrue'.
	generatorMethodBuilder addVariableNamed: 'jumpNext'.
	branch := self
		cogitBranchFromCondition: comparisonToGenerate condition
		type: comparisonToGenerate operand1 type.
	generatorMethodBuilder addStatement: (RBAssignmentNode
		variable: (RBVariableNode named: 'jumpTrue')
		value: (RBMessageNode
			receiver: RBVariableNode selfNode
			selector: branch
			arguments: { 0 asLiteralNode })).
	"Set false to result"
	self twoOperandMoveCogitRTL: aDRGetConditionCode 
		  operands: { 
				0 asDRValue.
				aDRGetConditionCode }.
	generatorMethodBuilder addStatement: (RBAssignmentNode
		variable: (RBVariableNode named: 'jumpNext')
		value: (RBMessageNode
			receiver: RBVariableNode selfNode
			selector: 'Jump:'
			arguments: { 0 asLiteralNode })).

	"true label"
	generatorMethodBuilder addStatement: (RBMessageNode
			receiver: (RBVariableNode named: 'jumpTrue')
			selector: #jmpTarget:
			arguments: { RBMessageNode
				receiver: RBVariableNode selfNode
				selector: #Label}).
	"Set true to result"
	self twoOperandMoveCogitRTL: aDRGetConditionCode
		  operands: { 
				1 asDRValue.
				aDRGetConditionCode }.

	"next label"
	generatorMethodBuilder addStatement: (RBMessageNode
			receiver: (RBVariableNode named: 'jumpNext')
			selector: #jmpTarget:
			arguments: { RBMessageNode
				receiver: RBVariableNode selfNode
				selector: #Label}).
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitGetFloatBits: aDRGetFloatBits [ 
	
	"This should be translated as a normal move"
	^ self visitCopy: aDRGetFloatBits
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitGetFloatFromBits: aDRGetFloatFromBits [

	"This should be translated as a normal move"
	^ self visitCopy: aDRGetFloatFromBits
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitGreaterOrEqualsThan: aDRGreaterThanComparison inBranch: aDRBranchIfCondition [ 
	
	^ self visitComparison: aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitGreaterThan: aDRGreaterThanComparison inBranch: aDRBranchIfCondition [ 
	
	^ self visitComparison: aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitIntToFloatConversion: aDRIntToFloat [

	^ self
		twoOperandCogitRTL: #Convert
		operands: { 
				aDRIntToFloat operand1.
				aDRIntToFloat result }
		instruction: aDRIntToFloat
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitJump: aDRJump [ 

	self
		generateJump: #Jump:
		target: aDRJump target
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitLeftShift: aDRCogitLeftShift [
	
	^ self threeOperandCogitRTL: #LogicalShiftLeft instruction: aDRCogitLeftShift
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitLessOrEqualsThan: aDRGreaterThanComparison inBranch: aDRBranchIfCondition [ 
	
	^ self visitComparison: aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitLessThan: aDRGreaterThanComparison inBranch: aDRBranchIfCondition [ 
	
	^ self visitComparison: aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitLoad: aDRLoad [

	self twoOperandMoveCogitRTL: aDRLoad
		operands: { 
				aDRLoad address.
				aDRLoad result }.

	aDRLoad size < 8 ifFalse: [ ^ self ].

	"If it is smaller than the word size, clean not used digits using a mask"
	self visitBitAnd: (DRBitAnd
			 operands: { 
					 aDRLoad result.
					 aDRLoad size maskOfBytes asDRValue }
			 result: aDRLoad result)
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitMod: aDRCogitDivision [

	"Cogit division (and thus remainder too) is not in 2AC but in 4AC.
	The (cogit specific) register allocator should inserts a register for quotient destination implicitly yet unused.
	It should also put all operands in registers as the cogit instruction does not support constants."

	^ generatorMethodBuilder addStatement: (RBMessageNode
			   receiver: RBVariableNode selfNode
			   selector: #DivR:R:Quo:Rem:
			   arguments: { 
					   (self rtlExpressionForValue: aDRCogitDivision operands second).
					   (self rtlExpressionForValue: aDRCogitDivision operands first).
					   (self rtlExpressionForValue: aDRCogitDivision operands third).
					   (self rtlExpressionForValue: aDRCogitDivision result) })
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitMultiply: aDRCogitMultiply [ 

	^ self threeOperandCogitRTL: #Mul instruction: aDRCogitMultiply

]

{ #category : #visiting }
DRCogitCodeGenerator >> visitMultiplyOverflow: aDRMultiplyOverflow inBranch: aDRBranchIfCondition [ 
	
	"Do nothing... Should we make sure nobody overwrote the overflow flag?"
	^ aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitMultiplyOverflowJump: aDROverflowJump [ 
	
	self generateJump: #JumpMultiplyOverflow: target: aDROverflowJump trueBranch.
	self generateJump: #JumpMultiplyNoOverflow: target: aDROverflowJump falseBranch.
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitNegate: aDRCogitNegate [ 
	
	self twoOperandMoveCogitRTL: aDRCogitNegate 
		operands: { aDRCogitNegate operand1. aDRCogitNegate result }.
		
	self flag: #todo. "oneOperandCogitRTL:"
	generatorMethodBuilder addStatement: (
		RBMessageNode
			receiver: RBVariableNode selfNode
			selector: #NegateR:
			arguments: { 
				RBVariableNode named: (self registerFor: aDRCogitNegate result) })
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitNoOverflow: aDRNoOverflow inBranch: aDRBranchIfCondition [ 

	"Do nothing... Should we make sure nobody overwrote the overflow flag?"
	^ aDRBranchIfCondition 
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitNoop: aDRNoop [ 
	
	"Do nothing"
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitNotEqualsThan: aDRGreaterThanComparison inBranch: aDRBranchIfCondition [ 
	
	^ self visitComparison: aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitNullValue: aDRNullValue [ 

	^ RBMessageNode
		receiver: RBVariableNode selfNode
		selector: #Nop
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitOr: aDROr [ 

	^ self threeOperandCogitRTL: #Or instruction: aDROr
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitOverflow: aDRMultiplyOverflow inBranch: aDRBranchIfCondition [ 
	
	"Do nothing... Should we make sure nobody overwrote the overflow flag?"
	^ aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitPhiFunction: aDRPhiFunction [ 

	"For the moment nothing"
	^ self visitNullValue: aDRPhiFunction
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitReturn: aDRReturn [

	"Generate the postamble in the return cases"
	self generatePostambleForCFG: aDRReturn controlFlowGraph.
	generatorMethodBuilder addStatement: (RBMessageNode
			 receiver: RBVariableNode selfNode
			 selector: #genPrimReturn)
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitRightShift: aDRCogitRightShift [ 

	^ self threeOperandCogitRTL: #ArithmeticShiftRight instruction: aDRCogitRightShift

]

{ #category : #visiting }
DRCogitCodeGenerator >> visitStore: aDRCogitStore [

	aDRCogitStore isJITCompileTimeExpression ifTrue: [
		^ self visitCompileTimeStore: aDRCogitStore ].

	^ self twoOperandMoveCogitRTL: aDRCogitStore operands: {
			  aDRCogitStore operand1.
			  aDRCogitStore operand2 asMemoryAddress }
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitSubstract: aDRCogitSubstract [ 
	
	^ self threeOperandCogitRTL: #Sub instruction: aDRCogitSubstract

]

{ #category : #visiting }
DRCogitCodeGenerator >> visitTestMask: aDRTestMask inBranch: aDRBranchIfCondition [

	| comparands |
	comparands := aDRBranchIfCondition operands.
	aDRBranchIfCondition operands second isConstant ifTrue: [ 
		comparands := comparands reversed ].
	self
		twoOperandCogitRTL: #Tst
		operands: comparands
		instruction: aDRBranchIfCondition.
	^ aDRBranchIfCondition
]

{ #category : #visiting }
DRCogitCodeGenerator >> visitUnsignedCoercion: aDRCogitUnsignedCoercion [ 

	^ self visitCopy: aDRCogitUnsignedCoercion
]
