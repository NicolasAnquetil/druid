Class {
	#name : #FCFGInstructionFactory,
	#superclass : #DRInstructionFactory,
	#category : #'FAST-CFG-utils'
}

{ #category : #factory }
FCFGInstructionFactory >> allocateTemporaryRegister [
	
	| allocatedRegisterId |
	allocatedRegisterId := nextAvailableRegister.
	nextAvailableRegister := nextAvailableRegister + 1.
	^ FCFGTemporaryRegister id: allocatedRegisterId
]

{ #category : #building }
FCFGInstructionFactory >> loadArgument: index [

	^ FCFGLoadArgument
		  operands: { index }
		  result: self allocateTemporaryRegister
]

{ #category : #building }
FCFGInstructionFactory >> phiWithVariables: variables [

	^ (FCFGPhiFunction joinedVariables: variables)
		  result: self allocateTemporaryRegister;
		  yourself
]
