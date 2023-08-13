Extension { #name : #FamixStUnknownVariable }

{ #category : #'*Druid' }
FamixStUnknownVariable >> druid: druidVisitor visit: aFASTNode [
	^druidVisitor visitVariableNode: aFASTNode
]
