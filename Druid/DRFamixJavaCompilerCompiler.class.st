Class {
	#name : #DRFamixJavaCompilerCompiler,
	#superclass : #DRAbstractCompilerCompiler,
	#category : #'Druid-CompilerCompiler'
}

{ #category : #'ir-generation' }
DRFamixJavaCompilerCompiler >> argName: index forMethod: method [

	^ (method parameters at: index) name
]

{ #category : #accessing }
DRFamixJavaCompilerCompiler >> drNode: method [
	^DRFASTJavaMethod methodNode: (self methodAST: method)
]

{ #category : #accessing }
DRFamixJavaCompilerCompiler >> methodAST: method [
	^method fast
]

{ #category : #'instance creation' }
DRFamixJavaCompilerCompiler >> newIRGenerator [

	^ DRFASTJavaIRGenerator new
]

{ #category : #'generation-IR' }
DRFamixJavaCompilerCompiler >> numberOfArgumentsForMethod: aMethod [ 

	^ aMethod parameters size
]
