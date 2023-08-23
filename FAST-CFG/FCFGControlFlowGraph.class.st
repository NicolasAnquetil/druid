Class {
	#name : #FCFGControlFlowGraph,
	#superclass : #DRControlFlowGraph,
	#category : #'FAST-CFG-model'
}

{ #category : #inspecting }
FCFGControlFlowGraph >> asInspectorIn: view [

	self configureVisualization: view.
	^ SpRoassal3InspectorPresenter new
		canvas: view;
		yourself
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

{ #category : #initialization }
FCFGControlFlowGraph >> initialize [

	super initialize.
	instructionFactory := FCFGInstructionFactory new.
]

{ #category : #inspecting }
FCFGControlFlowGraph >> inspectionCFG [

	<inspectorPresentationOrder: 0 title: 'CFG'>
	| view |
	view := RSCanvas new.
	^ self asInspectorIn: view
]

{ #category : #building }
FCFGControlFlowGraph >> privateNewBasicBlock [
	
	| newBlock |
	newBlock := FCFGBasicBlock id: self allocateBasicBlockID.
	newBlock controlFlowGraph: self.
	^ newBlock
]
