Class {
	#name : #FCFGBasicBlock,
	#superclass : #DRBasicBlock,
	#category : #'FAST-CFG-model'
}

{ #category : #building }
FCFGBasicBlock >> jumpTo: aBasicBlock [

	self endInstruction: (FCFGJump new target: aBasicBlock).
	(aBasicBlock hasPredecessor: self) ifFalse: [ 
		aBasicBlock addPredecessor: self ].
	^ endInstruction
]

{ #category : #'test - methods' }
FCFGBasicBlock >> return: anInstruction [ 
	^ self endInstruction: (FCFGReturn operands: { anInstruction } )
]
