Class {
	#name : #FCFGJump,
	#superclass : #FCFGInstruction,
	#instVars : [
		'target',
		'isBackJump'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGJump >> beBackJump [
	
	isBackJump := true
]

{ #category : #accessing }
FCFGJump >> beForwardJump [
	
	isBackJump := false
]

{ #category : #initialization }
FCFGJump >> initialize [

	super initialize.
	"result := DRNoRegister new."
	isBackJump := false
]

{ #category : #inspecting }
FCFGJump >> inspectionSource: aBuilder [
	<inspectorPresentationOrder: 0 title: 'Source'>

	^ SpCodePresenter new
		text: target asString;
		yourself
]

{ #category : #testing }
FCFGJump >> isBackJump [

	^ isBackJump
]

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

{ #category : #printing }
FCFGJump >> prettyPrint [

	^ 'Jump -> ', target id asString
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
