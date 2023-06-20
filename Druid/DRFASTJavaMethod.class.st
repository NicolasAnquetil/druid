Class {
	#name : #DRFASTJavaMethod,
	#superclass : #DRMethod,
	#category : #'Druid-FAST'
}

{ #category : #accessing }
DRFASTJavaMethod >> argumentNames [
	^self codeNode parameters collect: #name
]

{ #category : #execution }
DRFASTJavaMethod >> executeOn: aDRFASTJavaIRGenerator [

	| fastJavaVisitor |
	fastJavaVisitor := DRFASTJavaGeneratorVisitor new.
	fastJavaVisitor druidGenerator: aDRFASTJavaIRGenerator.
	aDRFASTJavaIRGenerator fastJavaVisitor: fastJavaVisitor.
	self codeNode accept: fastJavaVisitor
]

{ #category : #accessing }
DRFASTJavaMethod >> temporaryNames [
	^(self codeNode accept: DRFASTJavaLocalVarsVisitor new)
		reject: [:e | e class = FASTJavaNonLocalDeclaration ]
		thenCollect: [ :e | e variable name ].
]
