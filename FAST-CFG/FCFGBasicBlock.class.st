Class {
	#name : #FCFGBasicBlock,
	#superclass : #Object,
	#instVars : [
		'id',
		'endInstruction',
		'controlFlowGraph',
		'origin',
		'predecessors',
		'phiFunctions',
		'instructions'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #'instance creation' }
FCFGBasicBlock class >> id: anInteger [ 
	
	^ self new
		id: anInteger;
		yourself
]

{ #category : #instructions }
FCFGBasicBlock >> addInstruction: anInstruction [

	(self instructions includes: anInstruction) ifTrue: [ ^ self ].

	anInstruction basicBlock: self.

	^ (self collectionOf: anInstruction) add: anInstruction
]

{ #category : #accessing }
FCFGBasicBlock >> addPredecessor: aBasicBlock [

	predecessors add: aBasicBlock.
	self phiFunctions do: [ :phi | 
		phi operands size < self predecessors size ifTrue: [ phi addOperand ] ]
]

{ #category : #instructions }
FCFGBasicBlock >> basicEndInstruction: aDRInstruction [

	aDRInstruction basicBlock: self.
	^ endInstruction := aDRInstruction
]

{ #category : #instructions }
FCFGBasicBlock >> basicEndInstructionRemovingUsers: aDRInstruction [

	endInstruction ifNotNil: [ endInstruction operands do: [ :o | o removeUser: endInstruction ] ].
	^ self basicEndInstruction: aDRInstruction
]

{ #category : #accessing }
FCFGBasicBlock >> collectionOf: aDRInstruction [

	^ aDRInstruction isPhiFunction
		  ifTrue: [ phiFunctions ]
		  ifFalse: [ instructions ]
]

{ #category : #accessing }
FCFGBasicBlock >> controlFlowGraph [

	^ controlFlowGraph
]

{ #category : #accessing }
FCFGBasicBlock >> controlFlowGraph: anObject [

	controlFlowGraph := anObject
]

{ #category : #instructions }
FCFGBasicBlock >> endInstruction [

	^ endInstruction
]

{ #category : #instructions }
FCFGBasicBlock >> endInstruction: aDRInstruction [ 
	| previousSuccessors newSuccessors lostSuccessors |	
	previousSuccessors := self successors.
	newSuccessors := aDRInstruction targets.
	lostSuccessors := previousSuccessors difference: newSuccessors.
	
	lostSuccessors do: [ :e |
		e removePredecessor: self. ].

	self basicEndInstructionRemovingUsers: aDRInstruction.
	^ aDRInstruction
]

{ #category : #testing }
FCFGBasicBlock >> hasFinalInstruction [

	^ endInstruction notNil and: [ endInstruction isNoop not ]
]

{ #category : #testing }
FCFGBasicBlock >> hasPredecessor: aDRBasicBlock [ 
	
	^ predecessors includes: aDRBasicBlock
]

{ #category : #testing }
FCFGBasicBlock >> hasPredecessors [
	
	^ predecessors notEmpty
]

{ #category : #accessing }
FCFGBasicBlock >> id [

	^ id
]

{ #category : #accessing }
FCFGBasicBlock >> id: anObject [

	id := anObject
]

{ #category : #initialization }
FCFGBasicBlock >> initialize [
	super initialize.	
	"
	isExitBlock := false."
	phiFunctions := OrderedCollection new.
	instructions := OrderedCollection new.
	predecessors := OrderedCollection new.

	endInstruction := FCFGNoop new.
	endInstruction basicBlock: self.
]

{ #category : #instructions }
FCFGBasicBlock >> instructionFactory [
	
	^ controlFlowGraph instructionFactory
]

{ #category : #instructions }
FCFGBasicBlock >> instructions [

	| allInstructions |
	allInstructions := OrderedCollection new.
	self instructionsDo: [ :i | allInstructions add: i ].
	^ allInstructions
]

{ #category : #instructions }
FCFGBasicBlock >> instructionsDo: aFullBlockClosure [

	phiFunctions copy do: aFullBlockClosure.
	instructions copy do: aFullBlockClosure.
	endInstruction ifNotNil: [ aFullBlockClosure value: endInstruction ]
]

{ #category : #testing }
FCFGBasicBlock >> isEmptyBasicBlock [

	^ endInstruction isNoop and: [ self instructions allButLast isEmpty ]
]

{ #category : #building }
FCFGBasicBlock >> jumpTo: aBasicBlock [

	self endInstruction: (FCFGJump new target: aBasicBlock).
	(aBasicBlock hasPredecessor: self) ifFalse: [ 
		aBasicBlock addPredecessor: self ].
	^ endInstruction
]

{ #category : #building }
FCFGBasicBlock >> loadArgument: index [

	^ self addInstruction: (self instructionFactory loadArgument: index)
]

{ #category : #accessing }
FCFGBasicBlock >> origin: aCollection [ 
	origin := aCollection
]

{ #category : #accessing }
FCFGBasicBlock >> phiFunctions [
	
	^ phiFunctions
]

{ #category : #accessing }
FCFGBasicBlock >> predecessors [
	^ predecessors
]

{ #category : #instructions }
FCFGBasicBlock >> removeInstruction: aDRInstruction [

	endInstruction = aDRInstruction ifTrue: [ 
		^ self endInstruction: DRNoop new ].

	aDRInstruction isPhiFunction
		ifTrue: [ phiFunctions remove: aDRInstruction ]
		ifFalse: [ instructions remove: aDRInstruction ]
]

{ #category : #'test - methods' }
FCFGBasicBlock >> return: anInstruction [ 
	^ self endInstruction: (FCFGReturn operands: { anInstruction } )
]

{ #category : #accessing }
FCFGBasicBlock >> successors [
	
	^ endInstruction targets
]
