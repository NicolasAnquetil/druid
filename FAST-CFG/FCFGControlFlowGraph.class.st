Class {
	#name : #FCFGControlFlowGraph,
	#superclass : #Object,
	#instVars : [
		'initialBasicBlock',
		'instructionFactory',
		'basicBlocks',
		'nextBasicBlockId',
		'edgesBySource',
		'edges'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #accessing }
FCFGControlFlowGraph >> addBasicBlock: aBlock [

	self assert: (basicBlocks noneSatisfy: [:b | b id = aBlock id]).
	basicBlocks add: aBlock.
	^ aBlock
]

{ #category : #building }
FCFGControlFlowGraph >> allocateBasicBlockID [
	
	| allocatedID |
	allocatedID := nextBasicBlockId.
	nextBasicBlockId := nextBasicBlockId + 1.
	^ allocatedID
]

{ #category : #inspecting }
FCFGControlFlowGraph >> asInspectorIn: view [

	self configureVisualization: view.
	^ SpRoassal3InspectorPresenter new
		canvas: view;
		yourself
]

{ #category : #accessing }
FCFGControlFlowGraph >> blocks [

	^ basicBlocks
]

{ #category : #accessing }
FCFGControlFlowGraph >> blocksDo: aFullBlockClosure [ 

	basicBlocks do: aFullBlockClosure
]

{ #category : #inspecting }
FCFGControlFlowGraph >> configureVisualization: view [

	| blockViews controller |
	blockViews := self blocks collect: [ :b | self createBlockView: b. ].

	view addAll: blockViews.
	self showLines: blockViews in: view.

	"All the characters are displayed using a grid layout"
	RSSugiyamaLayout new
		horizontalGap: 50;
		applyOn: blockViews.

	self showInfoIn: view.

	controller := RSCanvasController new
		noLegend;
		yourself.

	view @ controller
]

{ #category : #inspecting }
FCFGControlFlowGraph >> createBlockView: aBlock [
	| box label boxes composite labelBackground |
	label := RSLabel new
		text: aBlock id asString;
		color: Color black;
		fontSize: 4;
		yourself.
	labelBackground := RSEllipse new
		color: Color white;
		border: (RSBorder new color: 'black');
		extent: label extent + 5;
		yourself.
	box := RSBox new
		noPaint;
		border: (RSBorder new
			width: 2;
			color: Color black;
			yourself);
		cornerRadius: 2;
		yourself.

	boxes := aBlock instructions collect: [ :inst |
		self createinstructionView: inst ] as: RSGroup.
	RSGridLayout on: boxes.

	box
		position: boxes position;
		extent: boxes extent + 10.
	composite := ({box},boxes) asShape
		draggable;
		@ (RSPopup text: [:model |
			String streamContents: [:s | (model instructions collect: #prettyPrint)
				asStringOn: s delimiter: String cr]
			]);
		@ (RSMenuActivable new menuDo: [ :menu :element |
			menu
				add: 'Tail-duplicate'
				target: element model
				selector: #tailDuplicate ]);
		model: aBlock;
		yourself.

	RSLocation new
		outer;
		right;
		top;
		offset: 3@(-3);
		move: label on: boxes.

	labelBackground position: label position.
	composite add: labelBackground.
	composite add: label.
	^ composite
]

{ #category : #inspecting }
FCFGControlFlowGraph >> createinstructionView: instruction [

	^ RSBox new
		  model: instruction;
		  color: (self instructionColor: instruction);
		  border: (RSBorder new
				   color: Color black;
				   joinMiter);
		  @ (RSMenuActivable new menuDo: [ :menu :element | 
				   menu
					   add: 'Inline'
					   target: element model
					   selector: #inline;
						add: 'Unroll'
					   target: element model
					   selector: #uiUnroll ]);
		  yourself
]

{ #category : #edges }
FCFGControlFlowGraph >> edgesFrom: sourceBlock to: destinationBlock [

	^ (self outgoingEdgesFor: sourceBlock) select: [ :e | e destination = destinationBlock ]
]

{ #category : #accessing }
FCFGControlFlowGraph >> firstBasicBlock [

	^ initialBasicBlock successor
]

{ #category : #edges }
FCFGControlFlowGraph >> incomingEdgesFor: aBlock [

	^ edges select: [ :e | e destination = aBlock ]
]

{ #category : #accessing }
FCFGControlFlowGraph >> initialBasicBlock [ 
	^ initialBasicBlock
]

{ #category : #initialization }
FCFGControlFlowGraph >> initialize [

	super initialize.
	instructionFactory := FCFGInstructionFactory new.

	basicBlocks := OrderedCollection new.
	edges := OrderedCollection new.
	edgesBySource := Dictionary new.

	nextBasicBlockId := 0.
	initialBasicBlock := self privateNewBasicBlock.
]

{ #category : #inspecting }
FCFGControlFlowGraph >> inspectionCFG [

	<inspectorPresentationOrder: 0 title: 'CFG'>
	| view |
	view := RSCanvas new.
	^ self asInspectorIn: view
]

{ #category : #inspecting }
FCFGControlFlowGraph >> instructionColor: instruction [

	instruction isJump ifTrue: [
		instruction isBackJump ifTrue: [ ^ Color purple muchLighter ].
		instruction isBranchIfCondition ifTrue: [ ^ Color purple ].
		instruction isBranchIfTrue ifTrue: [ ^ Color purple ].
		^ Color purple muchDarker ].
	instruction isMandatoryInstruction ifTrue: [ ^ Color red ].
	instruction users isEmpty ifTrue: [ ^ Color gray ].
	instruction isPhiFunction ifTrue: [ ^ Color orange ].
	(instruction operands anySatisfy: [ :op | op isPhysicalRegister ])
		ifTrue: [ ^ Color red darker ].
	(instruction operands anySatisfy: [ :op | op isConstant ]) ifTrue: [
		^ Color yellow darker ].
	instruction isCopy ifTrue: [ ^ Color blue muchLighter ].

	^ Color white
]

{ #category : #accessing }
FCFGControlFlowGraph >> instructionFactory [

	^ instructionFactory
]

{ #category : #accessing }
FCFGControlFlowGraph >> instructionFactory: anObject [

	instructionFactory := anObject
]

{ #category : #accessing }
FCFGControlFlowGraph >> instructions [
	
	| instructions |
	instructions := OrderedCollection new.
	self instructionsDo: [ :e |
		instructions add: e ].
	^ instructions
]

{ #category : #accessing }
FCFGControlFlowGraph >> instructionsDo: aFullBlockClosure [

	self blocksDo: [ :b | 
		b instructionsDo: [ :e | aFullBlockClosure value: e ] ]
]

{ #category : #testing }
FCFGControlFlowGraph >> isAlmostDeadBranch: aDRBasicBlock to: aDRBasicBlock2 [

	^ (self edgesFrom: aDRBasicBlock to: aDRBasicBlock2) anySatisfy: [ :e | 
		  e isDead ]
]

{ #category : #testing }
FCFGControlFlowGraph >> isDeadBranch: aDRBasicBlock to: aDRBasicBlock2 [

	^ (self edgesFrom: aDRBasicBlock to: aDRBasicBlock2) allSatisfy: [ :e | 
		  e isDead ]
]

{ #category : #accessing }
FCFGControlFlowGraph >> lastPaths [

	^ (self blocks
		   select: [ :b | b successors isEmpty ]
		   thenCollect: [ :b | self incomingEdgesFor: b ]) flattened
]

{ #category : #building }
FCFGControlFlowGraph >> newBasicBlock [
	
	^ self addBasicBlock: self privateNewBasicBlock
]

{ #category : #edges }
FCFGControlFlowGraph >> outgoingEdgesFor: aBlock [

	^ edgesBySource at: aBlock ifAbsent: [ #() ]
]

{ #category : #accessing }
FCFGControlFlowGraph >> pathsSize [

	^ self lastPaths size
]

{ #category : #building }
FCFGControlFlowGraph >> privateNewBasicBlock [
	
	| newBlock |
	newBlock := FCFGBasicBlock id: self allocateBasicBlockID.
	newBlock controlFlowGraph: self.
	^ newBlock
]

{ #category : #inspecting }
FCFGControlFlowGraph >> showBranchConstraints: branchEdges [

	^ String streamContents: [ :s | 
		  branchEdges
			  do: [ :e | 
				  e constraints associationsDo: [ :assoc | 
					  s << (assoc key asString , ' ' , assoc value asString , String cr) ] ]
			  separatedBy: [ 
				  s << (String cr , '--o--o--o--o--o--o--o--' , String cr) ] ]
]

{ #category : #inspecting }
FCFGControlFlowGraph >> showInfoIn: view [

	| label instructions blocks paths info |
		
	label := [ :text | 
	         RSLabel new
		         text: text;
		         color: Color black;
		         fontSize: 14;
		         bold;
		         yourself ].


	blocks := label value: self blocks size asString , ' blocks'.
	instructions := label value:
		                self instructions size asString , ' instructions'.
	paths := label value: self pathsSize asString , ' paths'.
	info := { blocks . instructions .  paths }.

	RSVerticalLineLayout new
		alignLeft;
		on: info.
	info := info asShape.
	 
	RSLocation new
		below;
		offset:( 0 @ 20);
		move: info on: view.

	view add: info
]

{ #category : #inspecting }
FCFGControlFlowGraph >> showLines: blockViews in: view [

	| eb |
	eb := RSLineBuilder arrowedLine.
	eb canvas: view.
	eb color: Color blue muchDarker.
	eb width: 2.
	eb withBorderAttachPoint.
	eb shapes: blockViews.
	eb connectToAll: #successors.

	view lines pushBack.
	view lines do: [ :line |
		| source destination |
		source := line model key.
		destination := line model value.
		line model: (self edgesFrom: source to: destination).
		line @ (RSPopup text: [ :edgs | self showBranchConstraints: edgs ]).
		(self isAlmostDeadBranch: source to: destination) ifTrue: [
			line color: Color green muchDarker ].
		(self isDeadBranch: source to: destination) ifTrue: [
			line color: Color red muchDarker ] ]
]
