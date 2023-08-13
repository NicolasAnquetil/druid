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
DRFASTPharoIRGeneratorTest >> astFor: aCompiledMethod [
	"generates a FAST-Pharo tree from the source code of the compiled method
	 + makes the bindings of variables"
	| ast binder |

	ast := FASTSmalltalkImporterVisitor new
		runWithSource: aCompiledMethod sourceCode.
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
	self bind: 'fastJavaVisitor' to: FamixStAttribute.
	ir := self generateIRFor: (DRFASTJavaIRGenerator >> #fastJavaVisitor).

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assert: block class equals: DRBasicBlock.
	self assert: block instructions size equals: 1.
	self assert: block endInstruction class equals: DRJump.
	self assert: block endInstruction target equals: (self block: ir at: 2).
	self deny: block isExitBlock.

	block := self block: ir at: 2.
	self assert: block class equals: DRBasicBlock.
	self assert: block instructions size equals: 3.
	self assert: block instructions first class equals: DRLoadInstanceVariable.
	self assert: block instructions second class equals: DRFrameReturn.
	self assert: block endInstruction class equals: DRJump.
	self assert: block endInstruction target equals: (self block: ir at: 3).
	self deny: block isExitBlock.

	block := self block: ir at: 3.
	self assert: block class equals: DRBasicBlock.
	self assert: block instructions size equals: 3.
	self assert: block instructions first class equals: DRPhiFunction.
	self assert: block instructions second class equals: DRFrameReturn.
	self assert: block endInstruction class equals: DRReturn.
	self deny: block isExitBlock.

]

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testSetterMethod [
	| ir block |
	self bind: 'fastJavaVisitor' to: FamixStAttribute.
	self bind: 'anObject' to: FamixStParameter.
	ir := self generateIRFor: (DRFASTJavaIRGenerator >> #fastJavaVisitor:).

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assert: block class equals: DRBasicBlock.
	self assert: block instructions size equals: 2.
	self assert: block instructions first class equals: DRLoadArgument.
	self assert: block endInstruction class equals: DRJump.
	self assert: block endInstruction target equals: (self block: ir at: 2).
	self deny: block isExitBlock.

	block := self block: ir at: 2.
	self assert: block class equals: DRBasicBlock.
	self assert: block instructions size equals: 3.
	self assert: block instructions first class equals: DRStoreInstanceVariable.
	self assert: block instructions second class equals: DRFrameReturn.
	self assert: block endInstruction class equals: DRJump.
	self assert: block endInstruction target equals: (self block: ir at: 3).
	self deny: block isExitBlock.

	block := self block: ir at: 3.
	self assert: block class equals: DRBasicBlock.
	self assert: block instructions size equals: 3.
	self assert: block instructions first class equals: DRPhiFunction.
	self assert: block instructions second class equals: DRFrameReturn.
	self assert: block endInstruction class equals: DRReturn.
	self deny: block isExitBlock.

]
