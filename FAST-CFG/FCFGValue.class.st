Class {
	#name : #FCFGValue,
	#superclass : #Object,
	#category : #'FAST-CFG-model'
}

{ #category : #adding }
FCFGValue >> addUser: anInstruction [
	
	"Nothing"
]

{ #category : #accessing }
FCFGValue >> asDependencyList [

	"Return myself as a list of dependencies, independently of MY dependencies"	
	^ { self }
]

{ #category : #accessing }
FCFGValue >> dependencies [
	
	^ self operands flatCollect: [ :op | op asDependencyList ]
]

{ #category : #testing }
FCFGValue >> isBlockClosure [
	
	^ false
]

{ #category : #testing }
FCFGValue >> isConstant [
	
	^ false
]

{ #category : #testing }
FCFGValue >> isCopy [ 
	
	^ false
]

{ #category : #testing }
FCFGValue >> isInstruction [

	^ false
]

{ #category : #testing }
FCFGValue >> isJump [ 

	^ false
]

{ #category : #testing }
FCFGValue >> isMandatoryInstruction [

	^ false
]

{ #category : #testing }
FCFGValue >> isNoop [ 
	
	^ false
]

{ #category : #testing }
FCFGValue >> isPhiFunction [

	^ false
]

{ #category : #testing }
FCFGValue >> isPhysicalRegister [

	^ false
]

{ #category : #accessing }
FCFGValue >> operands [
	
	^ #()
]

{ #category : #printing }
FCFGValue >> printResult [

	^ self value asString
]

{ #category : #removing }
FCFGValue >> removeUser: anInstruction [
	
	"Nothing"
]

{ #category : #accessing }
FCFGValue >> targets [

	^ #()
]
