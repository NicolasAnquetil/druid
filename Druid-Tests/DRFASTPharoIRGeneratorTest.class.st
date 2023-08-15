"
A DRFASTPharoIRGeneratorTest is a test class for testing the behavior of DRFASTPharoIRGenerator
"
Class {
	#name : #DRFASTPharoIRGeneratorTest,
	#superclass : #TestCase,
	#instVars : [
		'bindings'
	],
	#category : #'Druid-Tests-FAST-Pharo'
}

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> aSelector [
	bindings := self
]

{ #category : #running }
DRFASTPharoIRGeneratorTest >> assertBlockInstructions: aDRBlock contains: aClassCollection [
	
	self assert: aDRBlock class equals: DRBasicBlock.

	self assert: aDRBlock instructions size equals: aClassCollection size.
	
	aDRBlock instructions with: aClassCollection do: [ :inst :clazz |
		self assert: inst class equals: clazz
	].

]

{ #category : #running }
DRFASTPharoIRGeneratorTest >> astFor: sourceCode [
	"generates a FAST-Pharo tree from the source code of the compiled method
	 + makes the bindings of variables"
	| ast binder |

	ast := FASTSmalltalkImporterVisitor new
		runWithSource: sourceCode.
	binder := DRFASTPharoBinderForTest new
		on: ast ;
		yourself.

	bindings keysAndValuesDo: [ :name :famixEntity |
		binder bind: name to: famixEntity
	].

^ ast
]

{ #category : #running }
DRFASTPharoIRGeneratorTest >> bind: aName to: aFamixClass [

	"records the binding to make it after creating the AST.
	Returns the binded famixEntity to give a chance to set additional properties on it"

	| famixEntity |
	famixEntity := aFamixClass new
		 name: aName;
		 yourself.
	bindings at: aName put: famixEntity.

	^famixEntity 
]

{ #category : #running }
DRFASTPharoIRGeneratorTest >> block: ir at: i [
	^ir blocks
		detect: [ :block | block id = i ]
		ifNone: [ nil ]
]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> generateIRFor: aCompiledMethod [
	^DRFASTPharoCompilerCompiler new
		generateDruidIRFor: (self astFor: aCompiledMethod)
]

{ #category : #initialization }
DRFASTPharoIRGeneratorTest >> initialize [
	super initialize.
	
	bindings := Dictionary new

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testInstanceVarGetter [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'anInstVarGetter
	^anInstVar'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {DRLoadInstanceVariable. DRFrameReturn. DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: { DRPhiFunction. DRFrameReturn. DRReturn}.

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testMessageSend [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar otherSelector'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {DRLoadInstanceVariable . DRFASTMessageSend . DRFrameReturn . DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {DRPhiFunction. DRFrameReturn. DRReturn}.

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testParameterSetter [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	self bind: 'anObject' to: FamixStParameter.
	ir := self generateIRFor:
'anInstVarSetter: anObject
	anInstVar := anObject'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: { DRLoadArgument. DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {DRStoreInstanceVariable. DRFrameReturn. DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {DRPhiFunction. DRFrameReturn. DRReturn}.

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testSelfAccess [
	| ir block |
	ir := self generateIRFor:
'aSelector
	self otherSelector'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {DRFASTMessageSend . DRFrameReturn . DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {DRPhiFunction. DRFrameReturn. DRReturn}.

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testSelfAssigned [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := self'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {DRStoreInstanceVariable . DRFrameReturn . DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {DRPhiFunction. DRFrameReturn. DRReturn}.

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testSuperAccess [
	| ir block |
	ir := self generateIRFor:
'aSelector
	super otherSelector'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {DRFASTMessageSend . DRFrameReturn . DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {DRPhiFunction. DRFrameReturn. DRReturn}.

]
