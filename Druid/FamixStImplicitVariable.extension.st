Extension { #name : #FamixStImplicitVariable }

{ #category : #'*Druid' }
FamixStImplicitVariable >> druid: druidVisitor visit: aFASTNode [
	^(self name = 'super')
		ifTrue: [ druidVisitor visitSelfNode: aFASTNode]
		ifFalse: [ druidVisitor visitSuperNode: aFASTNode]
]
