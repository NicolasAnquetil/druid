Class {
	#name : #FCFGInterpreterValue,
	#superclass : #FCFGValue,
	#instVars : [
		'value'
	],
	#category : #'FAST-CFG-model'
}

{ #category : #'instance creation' }
FCFGInterpreterValue class >> value: anInterpreterObject [

	^ self new
		  value: anInterpreterObject value;
		  yourself
]

{ #category : #accessing }
FCFGInterpreterValue >> value [

	^ value
]

{ #category : #accessing }
FCFGInterpreterValue >> value: anObject [

	value := anObject
]
