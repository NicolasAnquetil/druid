Extension { #name : #FamixStGlobalVariable }

{ #category : #'*Druid' }
FamixStGlobalVariable >> druid: druidVisitor visit: aFASTNode [
	^druidVisitor visitGlobalVariableNode: aFASTNode
]
