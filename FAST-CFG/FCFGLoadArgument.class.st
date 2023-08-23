Class {
	#name : #FCFGLoadArgument,
	#superclass : #DRLoadArgument,
	#category : #'FAST-CFG-model'
}

{ #category : #printing }
FCFGLoadArgument >> opcode [
	
	^ 'LoadArgument', argNum asString
]
