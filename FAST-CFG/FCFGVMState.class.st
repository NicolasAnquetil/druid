Class {
	#name : #FCFGVMState,
	#superclass : #DRVMState,
	#category : #'FAST-CFG-model'
}

{ #category : #adding }
FCFGVMState >> addStackOperand: operand at: stackPosition [

	| stackOperandPhi |
	"Fill with empty phis if necessary"
	[ stackPosition > operandStack size ] whileTrue: [ 
		operandStack push:
			(builder instructionFactory
				phiWithVariables: OrderedCollection new) ].

	stackOperandPhi := operandStack at: stackPosition.
	"If the operand did not change, do nothing"
	stackOperandPhi == operand ifTrue: [ ^ self ].
	
	"Block closures are special and we do not handle polymorphic blocks.
	If the temporary is a block closure, override the phi function.
	Avoid overriding block closures too"
	stackOperandPhi isBlockClosure ifTrue: [ 
		self error: 'cannot override block closures in the stack' ].
	
	operand isBlockClosure ifTrue: [
		^ operandStack at: stackPosition put: operand ].
	
	"Otherwise, accumulate it"
	stackOperandPhi addValue: operand
]
