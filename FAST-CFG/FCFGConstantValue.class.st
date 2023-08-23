Class {
	#name : #FCFGConstantValue,
	#superclass : #FCFGValue,
	#instVars : [
		'value'
	],
	#classInstVars : [
		'value'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #'instance creation' }
FCFGConstantValue class >> value: anInteger [
	
	^ self new
		value: anInteger;
		yourself
]

{ #category : #testing }
FCFGConstantValue >> isConstant [
	
	^true
]

{ #category : #testing }
FCFGConstantValue >> value [
	^ value
]

{ #category : #testing }
FCFGConstantValue >> value: anInteger [ 

	value := anInteger
]
