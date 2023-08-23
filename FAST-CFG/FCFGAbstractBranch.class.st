Class {
	#name : #FCFGAbstractBranch,
	#superclass : #FCFGInstruction,
	#instVars : [
		'backJumps',
		'trueBranch',
		'falseBranch'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #initialization }
FCFGAbstractBranch >> backJumpTargets [
	^ backJumps.
]

{ #category : #accessing }
FCFGAbstractBranch >> falseBranch [
	^ falseBranch
]

{ #category : #accessing }
FCFGAbstractBranch >> falseBranch: aDRBasicBlock [ 

	backJumps remove: falseBranch ifAbsent: [  ].
	falseBranch := aDRBasicBlock
	
]

{ #category : #initialization }
FCFGAbstractBranch >> initialize [

	super initialize.
	"result := DRNoRegister new."
	backJumps := Set new
]

{ #category : #testing }
FCFGAbstractBranch >> isBackJump [

	^ backJumps isNotEmpty
]

{ #category : #printing }
FCFGAbstractBranch >> opcode [
	
	^ 'If'
]

{ #category : #accessing }
FCFGAbstractBranch >> targets [

	^ { trueBranch . falseBranch }
]

{ #category : #accessing }
FCFGAbstractBranch >> trueBranch [

	^ trueBranch
]

{ #category : #accessing }
FCFGAbstractBranch >> trueBranch: aDRBasicBlock [

	backJumps remove: trueBranch ifAbsent: [  ].

	trueBranch := aDRBasicBlock
]
