Class {
	#name : #DRFASTJavaCompilerCompiler,
	#superclass : #DRAbstractCompilerCompiler,
	#category : #'FAST-CFG-Java'
}

{ #category : #'ir-generation' }
DRFASTJavaCompilerCompiler >> argName: index forMethod: method [

	^ (method parameters at: index) name
]

{ #category : #accessing }
DRFASTJavaCompilerCompiler >> drNode: method [
	^DRFASTJavaMethod methodNode: (self methodAST: method)
]

{ #category : #accessing }
DRFASTJavaCompilerCompiler >> methodAST: method [
	^method
]

{ #category : #'instance creation' }
DRFASTJavaCompilerCompiler >> newIRGenerator [

	^ DRFASTJavaIRGenerator new
]

{ #category : #'generation-IR' }
DRFASTJavaCompilerCompiler >> numberOfArgumentsForMethod: aMethod [ 

	^ aMethod parameters size
]
