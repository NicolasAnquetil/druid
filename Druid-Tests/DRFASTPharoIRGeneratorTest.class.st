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

{ #category : #running }
DRFASTPharoIRGeneratorTest >> assertInstructions: aDRBlock match: aClassCollection [
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
DRFASTPharoIRGeneratorTest >> testGetterMethod [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'anInstVarGetter
	^anInstVar'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assert: block class equals: DRBasicBlock.
	self assertInstructions: block match: {DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assert: block class equals: DRBasicBlock.
	self assertInstructions: block match: {DRLoadInstanceVariable. DRFrameReturn. DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assert: block class equals: DRBasicBlock.
	self assertInstructions: block match: { DRPhiFunction. DRFrameReturn. DRReturn}.

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testSetterMethod [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	self bind: 'anObject' to: FamixStParameter.
	ir := self generateIRFor:
'anInstVarSetter: anObject
	anInstVar := anObject'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assert: block class equals: DRBasicBlock.
	self assertInstructions: block match: { DRLoadArgument. DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assert: block class equals: DRBasicBlock.
	self assertInstructions: block match: {DRStoreInstanceVariable. DRFrameReturn. DRJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assert: block class equals: DRBasicBlock.
	self assertInstructions: block match: {DRPhiFunction. DRFrameReturn. DRReturn}.

]
