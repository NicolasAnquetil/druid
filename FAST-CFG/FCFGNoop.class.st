Class {
	#name : #FCFGNoop,
	#superclass : #FCFGInstruction,
	#category : #'FAST-CFG-model'
}

{ #category : #testing }
FCFGNoop >> isNoop [ 
	
	^true
]

{ #category : #printing }
FCFGNoop >> opcode [
	
	^ 'Noop'
]
