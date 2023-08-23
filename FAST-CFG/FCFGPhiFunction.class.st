Class {
	#name : #FCFGPhiFunction,
	#superclass : #FCFGInstruction,
	#category : #'FAST-CFG-model'
}

{ #category : #'instance creation' }
FCFGPhiFunction class >> joinedVariables: aCollection [ 

	^ self new
		joinedVariables: aCollection;
		yourself
]

{ #category : #adding }
FCFGPhiFunction >> addValue: anInstruction [

	operands add: anInstruction.
	anInstruction addUser: self.
]

{ #category : #testing }
FCFGPhiFunction >> isPhiFunction [

	^true
]

{ #category : #accessing }
FCFGPhiFunction >> joinedVariables: aCollection [
	self operands: aCollection
]
