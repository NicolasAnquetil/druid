Class {
	#name : #FCFGInstruction,
	#superclass : #FCFGValue,
	#instVars : [
		'operands',
		'basicBlock'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGInstruction class >> operands: aCollection [
	
	"Validate operands collections size?"
	^ self new
		operands: aCollection;
		yourself
]

{ #category : #accessing }
FCFGInstruction >> basicBlock [

	^ basicBlock
]

{ #category : #accessing }
FCFGInstruction >> basicBlock: anObject [

	basicBlock := anObject
]

{ #category : #testing }
FCFGInstruction >> hasDependency: anInstruction [
	
	^ self dependencies includes: anInstruction
]

{ #category : #initialization }
FCFGInstruction >> initialize [

	super initialize.
	operands := #().
]

{ #category : #accessing }
FCFGInstruction >> operands [

	^ operands
]

{ #category : #accessing }
FCFGInstruction >> operands: aCollection [

	operands asSet do: [ :each | each removeUser: self ].
	operands := aCollection asOrderedCollection.
	self dependencies asSet do: [ :each | each addUser: self ]
]
