Extension { #name : #FASTEntity }

{ #category : #'*Druid' }
FASTEntity >> acceptVisitor: aFASTVisitor [
	^ self accept: aFASTVisitor fastVisitor
]

{ #category : #'*Druid' }
FASTEntity >> isReturn [
	^false
]
