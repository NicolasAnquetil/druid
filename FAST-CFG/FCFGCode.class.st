Class {
	#name : #FCFGCode,
	#superclass : #FCFGInstruction,
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGCode >> argumentNames [
	^self codeNode argumentNames
]

{ #category : #activation }
FCFGCode >> basicNewFrame [

	^ self subclassResponsibility
]

{ #category : #activation }
FCFGCode >> codeNode [

	self subclassResponsibility
]

{ #category : #activation }
FCFGCode >> defaultReturnValue: receiver [

	^ self subclassResponsibility
]

{ #category : #activation }
FCFGCode >> pushFrame: frame In: interpreter receiver: aReceiver [

	| newMethodEntry incomingBasicBlock |
	"Store the current execution state before the call.
	We will restore it just after the return"
	incomingBasicBlock := interpreter currentBasicBlock.
	newMethodEntry := interpreter newBasicBlock.
	incomingBasicBlock jumpTo: newMethodEntry.

	frame
		receiver: aReceiver;
		method: self codeNode;
		irGenerator: interpreter;
		entryBasicBlock: newMethodEntry;
		exitBasicBlock: interpreter basicNewBasicBlock.

	self temporaryNames , self argumentNames do: [ :e | frame defineVariableNamed: e ].
	frame returnValue: (self defaultReturnValue: aReceiver).
	interpreter pushFrame: frame.
	^ frame
]

{ #category : #activation }
FCFGCode >> pushFrameIn: interpreter receiver: aReceiver [

	^ self pushFrame: self basicNewFrame In: interpreter receiver: aReceiver
]

{ #category : #accessing }
FCFGCode >> temporaryNames [
	^self codeNode temporaryNames
]
