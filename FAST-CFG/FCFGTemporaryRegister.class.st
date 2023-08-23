Class {
	#name : #FCFGTemporaryRegister,
	#superclass : #FCFGValue,
	#instVars : [
		'id'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGTemporaryRegister class >> id: anInteger [ 
	
	^ self new
		id: anInteger;
		yourself
]

{ #category : #accessing }
FCFGTemporaryRegister >> hash [
	^id hash
]

{ #category : #accessing }
FCFGTemporaryRegister >> id [

	^ id
]

{ #category : #accessing }
FCFGTemporaryRegister >> id: anObject [

	id := anObject
]

{ #category : #accessing }
FCFGTemporaryRegister >> name [

	^ 'R' , self id asString
]
