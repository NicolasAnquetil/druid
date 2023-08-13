Extension { #name : #FamixStAttribute }

{ #category : #'*Druid' }
FamixStAttribute >> druid: druidVisitor visit: aFASTNode [
	^self isClassSide
		ifTrue: [ druidVisitor visitClassVariableNode: aFASTNode ]
		ifFalse: [ druidVisitor visitInstanceVariableNode: aFASTNode ]
	
]
