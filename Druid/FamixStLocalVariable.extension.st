Extension { #name : #FamixStLocalVariable }

{ #category : #'*Druid' }
FamixStLocalVariable >> druid: druidVisitor visit: aFASTNode [
	^druidVisitor visitLocalVariableNode: aFASTNode
]
