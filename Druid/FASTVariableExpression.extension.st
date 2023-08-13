Extension { #name : #FASTVariableExpression }

{ #category : #'*Druid' }
FASTVariableExpression >> famixVariable [
	^self propertyNamed: #famixVariable
]

{ #category : #'*Druid' }
FASTVariableExpression >> famixVariable: aFamixEntity [
	self propertyNamed: #famixVariable put: aFamixEntity
]
