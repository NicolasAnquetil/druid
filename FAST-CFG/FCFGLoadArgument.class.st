Class {
	#name : #FCFGLoadArgument,
	#superclass : #FCFGInstruction,
	#instVars : [
		'argName',
		'argNum'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGLoadArgument >> argName [

	^ argName
]

{ #category : #accessing }
FCFGLoadArgument >> argName: selector [

	argName := selector
]

{ #category : #printing }
FCFGLoadArgument >> opcode [
	
	^ 'LoadArgument', argNum asString
]

{ #category : #accessing }
FCFGLoadArgument >> operands: operandList [

	argNum := operandList first value.
	super operands: operandList allButFirst
]
