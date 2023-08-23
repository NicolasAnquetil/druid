Class {
	#name : #FCFGInstruction,
	#superclass : #FCFGValue,
	#instVars : [
		'operands',
		'basicBlock',
		'result',
		'origin',
		'originAST',
		'users'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #'instance creation' }
FCFGInstruction class >> operands: aCollection [
	
	"Validate operands collections size?"
	^ self new
		operands: aCollection;
		yourself
]

{ #category : #'instance creation' }
FCFGInstruction class >> operands: aCollection result: aResultRegister [
	
	"Validate operands collections size?"
	^ self new
		operands: aCollection;
		result: aResultRegister;
		yourself
]

{ #category : #adding }
FCFGInstruction >> addUser: anInstruction [

	users add: anInstruction
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
	users := IdentitySet new.
]

{ #category : #testing }
FCFGInstruction >> isInstruction [

	^true
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

{ #category : #accessing }
FCFGInstruction >> origin [

	^ origin
]

{ #category : #accessing }
FCFGInstruction >> origin: anObject [

	origin := anObject
]

{ #category : #accessing }
FCFGInstruction >> originAST [

	^ originAST
]

{ #category : #accessing }
FCFGInstruction >> originAST: anObject [

	originAST := anObject
]

{ #category : #removing }
FCFGInstruction >> removeFromCFG [

	basicBlock removeInstruction: self.
	self operands asSet do: [ :e | e removeUser: self ].
	self users asSet do: [ :e | e replaceDependency: self by: DRNullValue new  ]
]

{ #category : #removing }
FCFGInstruction >> removeUser: anInstruction [

	users remove: anInstruction
]

{ #category : #accessing }
FCFGInstruction >> result [

	^ result
]

{ #category : #accessing }
FCFGInstruction >> result: anObject [

	result := anObject
]

{ #category : #accessing }
FCFGInstruction >> users [

	^ users
]
