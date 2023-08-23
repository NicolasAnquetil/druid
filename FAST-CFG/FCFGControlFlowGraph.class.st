Class {
	#name : #FCFGControlFlowGraph,
	#superclass : #DRControlFlowGraph,
	#category : #'FAST-CFG-model'
}

{ #category : #initialization }
FCFGControlFlowGraph >> initialize [

	super initialize.
	instructionFactory := FCFGInstructionFactory new.
]

{ #category : #building }
FCFGControlFlowGraph >> privateNewBasicBlock [
	
	| newBlock |
	newBlock := FCFGBasicBlock id: self allocateBasicBlockID.
	newBlock controlFlowGraph: self.
	^ newBlock
]
