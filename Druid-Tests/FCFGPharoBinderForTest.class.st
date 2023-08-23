"
A visitor on FASTPharo tree to bind variable nodes to Famix entities

This fakes resolution of identifiers for variable by binding them to Famix entities

API:
- bind: aName to: aFamixEntity
  Looks for variable expressions in the AST with that name and set their famixVariable property to the Famix entity
"
Class {
	#name : #FCFGPharoBinderForTest,
	#superclass : #FASTPharoVisitor,
	#instVars : [
		'famixEntity',
		'searchedName',
		'fastTree'
	],
	#category : #'Druid-Tests-FAST-Pharo'
}

{ #category : #api }
FCFGPharoBinderForTest >> bind: aName to: aFamixEntity [
	searchedName := aName.
	famixEntity := aFamixEntity.

	fastTree accept: self
]

{ #category : #'instance creation' }
FCFGPharoBinderForTest >> on: aFASTtree [
	fastTree := aFASTtree
]

{ #category : #visiting }
FCFGPharoBinderForTest >> visitFASTVariableExpression: aFASTVariableExpression [
	(aFASTVariableExpression name = searchedName)
	ifTrue: [aFASTVariableExpression famixVariable: famixEntity]
]
