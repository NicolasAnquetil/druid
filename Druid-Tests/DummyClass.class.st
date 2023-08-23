Class {
	#name : #DummyClass,
	#superclass : #TestCase,
	#instVars : [
		'anInstVar'
	],
	#category : #'Druid-Tests-FAST-Pharo'
}

{ #category : #'as yet unclassified' }
DummyClass >> aSelector [
	anInstVar := false.
	anInstVar ifTrue: [^5 factorial].
	anInstVar := 'aString'
]

{ #category : #'as yet unclassified' }
DummyClass >> anInstVarSetter: anObject [
	anInstVar := anObject
]
