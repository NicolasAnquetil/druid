Extension { #name : #FamixStParameter }

{ #category : #'*Druid' }
FamixStParameter >> druid: druidVisitor visit: aFASTNode [
	^druidVisitor visitArgumentVariableNode: aFASTNode
]
