"
A DRFASTPharoIRGeneratorTest is a test class for testing the behavior of DRFASTPharoIRGenerator
"
Class {
	#name : #DRFASTPharoIRGeneratorTest,
	#superclass : #TestCase,
	#category : #'Druid-Tests-FAST-Pharo'
}

{ #category : #running }
DRFASTPharoIRGeneratorTest >> astFor: aCompiledMethod [
	^FASTSmalltalkImporterVisitor new
		runWithSource: aCompiledMethod sourceCode
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

{ #category : #tests }
DRFASTPharoIRGeneratorTest >> testGetterMethod [
	| ir block |
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
	self assert: block instructions size equals: 2.
	self assert: block instructions first class equals: DRFrameReturn.
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
