Class {
	#name : #DRFASTPharoCompilerCompiler,
	#superclass : #DRAbstractCompilerCompiler,
	#category : #'Druid-FAST-Pharo'
}

{ #category : #'ir-generation' }
DRFASTPharoCompilerCompiler >> argName: index forMethod: method [

	^ (method parameters at: index) name
]

{ #category : #accessing }
DRFASTPharoCompilerCompiler >> drNode: method [
	^DRFASTPharoMethod methodNode: (self methodAST: method)
]

{ #category : #accessing }
DRFASTPharoCompilerCompiler >> methodAST: method [
	^method
]

{ #category : #'instance creation' }
DRFASTPharoCompilerCompiler >> newIRGenerator [

	^ DRFASTPharoIRGenerator new
]

{ #category : #'generation-IR' }
DRFASTPharoCompilerCompiler >> numberOfArgumentsForMethod: aMethod [ 

	^ aMethod parameters size
]
