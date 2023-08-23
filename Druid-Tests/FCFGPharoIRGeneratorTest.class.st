"
A DRFASTPharoIRGeneratorTest is a test class for testing the behavior of DRFASTPharoIRGenerator
"
Class {
	#name : #FCFGPharoIRGeneratorTest,
	#superclass : #TestCase,
	#instVars : [
		'bindings',
		'anInstVar'
	],
	#category : #'Druid-Tests-FAST-Pharo'
}

{ #category : #running }
FCFGPharoIRGeneratorTest >> assertBlockInstructions: aDRBlock contains: aClassCollection [
	
	self assert: aDRBlock class equals: FCFGBasicBlock.

	self assert: aDRBlock instructions size equals: aClassCollection size.
	
	aDRBlock instructions with: aClassCollection do: [ :inst :clazz |
		self assert: inst class equals: clazz
	].

]

{ #category : #running }
FCFGPharoIRGeneratorTest >> astFor: sourceCode [
	"generates a FAST-Pharo tree from the source code of the compiled method
	 + makes the bindings of variables"
	| ast binder |

	ast := FASTSmalltalkImporterVisitor new
		runWithSource: sourceCode.
	binder := FCFGPharoBinderForTest new
		on: ast ;
		yourself.

	bindings keysAndValuesDo: [ :name :famixEntity |
		binder bind: name to: famixEntity
	].

^ ast
]

{ #category : #running }
FCFGPharoIRGeneratorTest >> bind: aName to: aFamixClass [

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
FCFGPharoIRGeneratorTest >> block: ir at: i [
	^ir blocks
		detect: [ :block | block id = i ]
		ifNone: [ nil ]
]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> exampleCFG [
	<script: 'FCFGPharoIRGeneratorTest new exampleCFG'>

	self bind: 'anInstVar' to: FamixStAttribute.
	(self generateIRFor:
'aSelector
	anInstVar := false.
	anInstVar ifTrue: [^5 factorial].
	anInstVar := ''aString''')
		inspect
]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> generateIRFor: aCompiledMethod [
	^FCFGPharoCompilerCompiler new
		generateDruidIRFor: (self astFor: aCompiledMethod)
]

{ #category : #initialization }
FCFGPharoIRGeneratorTest >> initialize [
	super initialize.
	
	bindings := Dictionary new

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testEmptyMethod [
	| ir block |
	ir := self generateIRFor:
'aSelector'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testIfTrue [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar ifTrue: []'.
	self assert: ir blocks size equals: 5.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGLoadInstanceVariable . FCFGBranchIfTrue }.
	self assert: block endInstruction trueBranch equals: (self block: ir at: 4).
	self assert: block endInstruction falseBranch equals: (self block: ir at: 5).

	block := self block: ir at: 4.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 5).

	block := self block: ir at: 5.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testIfTrueWithReturn [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar ifTrue: [^5]'.
	self assert: ir blocks size equals: 5.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGLoadInstanceVariable . FCFGBranchIfTrue }.
	self assert: block endInstruction trueBranch equals: (self block: ir at: 4).
	self assert: block endInstruction falseBranch equals: (self block: ir at: 5).

	block := self block: ir at: 4.
	self assertBlockInstructions: block contains: {FCFGCopy . FCFGFrameReturn . FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 5.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testIgnoreComments [
	| ir block |
	ir := self generateIRFor:
'aSelector
	"a comment"'.
	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testInstanceVarGetter [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'anInstVarGetter
	^anInstVar'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGLoadInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: { FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testLiteralBoolean [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := false'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGCopy . FCFGStoreInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testLiteralEmptyArray [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := #()'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGCopy . FCFGStoreInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testLiteralInteger [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := 42'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGCopy . FCFGStoreInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testLiteralNil [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := nil'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGCopy . FCFGStoreInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testLiteralString [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := ''aString'' '.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGCopy . FCFGStoreInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testLiteralSymbol [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := #blah'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGCopy . FCFGStoreInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testMessageSend [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar otherSelector'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {FCFGLoadInstanceVariable . FCFGMessageSend . FCFGFrameReturn . FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testParameterSetter [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	self bind: 'anObject' to: FamixStParameter.
	ir := self generateIRFor:
'anInstVarSetter: anObject
	anInstVar := anObject'.


	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: { FCFGLoadArgument . FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self assertBlockInstructions: block contains: {FCFGStoreInstanceVariable. FCFGFrameReturn. FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testSelfAccess [
	| ir block |
	ir := self generateIRFor:
'aSelector
	self otherSelector'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {FCFGMessageSend . FCFGFrameReturn . FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testSelfAssigned [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := self'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {FCFGStoreInstanceVariable . FCFGFrameReturn . FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testSuperAccess [
	| ir block |
	ir := self generateIRFor:
'aSelector
	super otherSelector'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {FCFGMessageSend . FCFGFrameReturn . FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]

{ #category : #tests }
FCFGPharoIRGeneratorTest >> testWithPharoBlock [
	| ir block |
	self bind: 'anInstVar' to: FamixStAttribute.
	ir := self generateIRFor:
'aSelector
	anInstVar := [ :a | a asString ]'.

	self assert: ir blocks size equals: 3.

	block := self block: ir at: 1.
	self assertBlockInstructions: block contains: {FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 2).

	block := self block: ir at: 2.
	self
		assertBlockInstructions: block
		contains: {FCFGStoreInstanceVariable . FCFGFrameReturn . FCFGJump}.
	self assert: block endInstruction target equals: (self block: ir at: 3).

	block := self block: ir at: 3.
	self assertBlockInstructions: block contains: {FCFGPhiFunction. FCFGFrameReturn. FCFGReturn}.

]
