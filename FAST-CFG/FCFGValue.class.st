Class {
	#name : #FCFGValue,
	#superclass : #Object,
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGValue >> dependencies [
	
	^ self operands flatCollect: [ :op | op asDependencyList ]
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

{ #category : #accessing }
FCFGValue >> targets [

	^ #()
]
