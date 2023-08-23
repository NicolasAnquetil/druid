Class {
	#name : #FCFGLoadInstanceVariable,
	#superclass : #FCFGInstruction,
	#category : #'FAST-CFG-model'
}

{ #category : #printing }
FCFGLoadInstanceVariable >> opcode [
	
	^ 'LoadInstVar'
]
