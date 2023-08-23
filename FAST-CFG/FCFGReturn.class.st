Class {
	#name : #FCFGReturn,
	#superclass : #FCFGInstruction,
	#category : #'FAST-CFG-model'
}

{ #category : #inspecting }
FCFGReturn >> inspectionSource: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Source'>

	^ SpCodePresenter new
		text: result asString;
		yourself
]

{ #category : #testing }
FCFGReturn >> isMandatoryInstruction [

	^ true
]

{ #category : #printing }
FCFGReturn >> opcode [
	
	^ 'Return'
]
