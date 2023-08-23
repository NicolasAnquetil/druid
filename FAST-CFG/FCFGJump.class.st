Class {
	#name : #FCFGJump,
	#superclass : #FCFGInstruction,
	#instVars : [
		'target'
	],
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

{ #category : #accessing }
FCFGJump >> target [
	^ target
]

{ #category : #accessing }
FCFGJump >> target: aBasicBlock [ 
	
	target := aBasicBlock
]

{ #category : #accessing }
FCFGJump >> targets [
	
	^ { target }
]
