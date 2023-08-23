Class {
	#name : #FCFGJump,
	#superclass : #DRJump,
	#category : #'FAST-CFG-model'
}

{ #category : #testing }
FCFGJump >> isJump [ 

	^ true
]

{ #category : #testing }
FCFGJump >> isMandatoryInstruction [
	
	^ true
]

{ #category : #printing }
FCFGJump >> opcode [
	
	^ 'Jump'
]
