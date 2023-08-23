Class {
	#name : #FCFGPharoCompilerCompiler,
	#superclass : #DRAbstractCompilerCompiler,
	#category : #'FAST-CFG-Pharo'
}

{ #category : #'ir-generation' }
FCFGPharoCompilerCompiler >> argName: index forMethod: method [

	^ (method parameters at: index) name
]

{ #category : #'generation-IR' }
FCFGPharoCompilerCompiler >> configureIRBuilder: generator forMethod: method [

	| startBlock initialBasicBlock |
	"Create the initial basic block"
	startBlock := generator initialBasicBlock.
	initialBasicBlock := generator createInitialBasicBlock.
	startBlock jumpTo: initialBasicBlock.

	generator receiver: (FCFGInterpreterValue value: interpreter).
	generator numberOfArguments: (self numberOfArgumentsForMethod: method)
]

{ #category : #accessing }
FCFGPharoCompilerCompiler >> drNode: method [
	^FCFGFASTPharoMethod methodNode: (self methodAST: method)
]

{ #category : #'generation-IR' }
FCFGPharoCompilerCompiler >> generateDruidIRFor: method [
	"Generates and returns an intermediate representation of the primitive from the interpreter primitive"

	| cfg receiver arguments |
	self configureIRBuilder: irGenerator forMethod: method.

	arguments := (1 to: (self numberOfArgumentsForMethod: method)) collect: [ :_ | irGenerator pop ].
	receiver := FCFGInterpreterValue value: interpreter.

	irGenerator
		interpretCode: (self drNode: method)
		receiver: receiver
		arguments: arguments.

	cfg := irGenerator ir.

	"Clean garbage to generate a valid CFG"
	DRDeadBlockElimination new applyTo: cfg.
	DRDeadCodeElimination new applyTo: cfg.
	"?? is validation necessary ??
	cfg validate."

	^ cfg
]

{ #category : #accessing }
FCFGPharoCompilerCompiler >> methodAST: method [
	^method
]

{ #category : #'instance creation' }
FCFGPharoCompilerCompiler >> newIRGenerator [

	^ FCFGPharoIRGenerator new
]

{ #category : #'generation-IR' }
FCFGPharoCompilerCompiler >> numberOfArgumentsForMethod: aMethod [ 

	^ aMethod parameters size
]
