Class {
	#name : #DRFASTPharoMethod,
	#superclass : #DRMethod,
	#category : #'Druid-FAST-Pharo'
}

{ #category : #accessing }
DRFASTPharoMethod >> argumentNames [
	^self codeNode parameters collect: #name
]

{ #category : #execution }
DRFASTPharoMethod >> executeOn: aDRFASTPharoIRGenerator [

	| fastPharoVisitor |
	fastPharoVisitor := DRFASTPharoGeneratorVisitor new.
	fastPharoVisitor druidGenerator: aDRFASTPharoIRGenerator.
	aDRFASTPharoIRGenerator fastPharoVisitor: fastPharoVisitor.
	self codeNode accept: fastPharoVisitor
]

{ #category : #accessing }
DRFASTPharoMethod >> temporaryNames [
	^(self codeNode accept: DRFASTJavaLocalVarsVisitor new)
		reject: [:e | e class = FASTJavaNonLocalDeclaration ]
		thenCollect: [ :e | e variable name ].
]
