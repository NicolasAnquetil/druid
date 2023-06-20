Class {
	#name : #DRFASTJavaLocalVarsVisitor,
	#superclass : #FASTJavaLocalResolverVisitor,
	#category : #'Druid-FAST'
}

{ #category : #visiting }
DRFASTJavaLocalVarsVisitor >> visitFASTJavaMethodEntity: aFASTJavaMethodEntity [
	"cannot trust in visit children because order of parameters and statementBlock is not guaranteed"

	"aFASTJavaMethodEntity modifiers"
	"aFASTJavaMethodEntity type"
	"aFASTJavaMethodEntity name"
	aFASTJavaMethodEntity parameters do: [: node | node accept: self ].
	"aFASTJavaMethodEntity throws"
	^aFASTJavaMethodEntity statementBlock accept: self.
]
