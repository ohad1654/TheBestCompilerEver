namespace JACKtoVM

import System
import System.Collections.Generic

class SymbolTable:
"""Description of SymbolTable"""
	
	typeMap as Dictionary[of string, string]
	kindMap as Dictionary[of string, Kind]
	indexMap as Dictionary[of string, int]
	
	indexes as List[of int]

	
	public def constructor():
		reset()
		
		
		
	public def reset():
		typeMap = Dictionary[of string, string]()
		kindMap = Dictionary[of string, Kind]()
		indexMap = Dictionary[of string, int]()
		//create a list of 0 with length of the Kind enum
		indexes = List[of int]()
		while(indexes.Count<Enum.GetNames(Kind).GetLength(0)):
			indexes.Add(0)
	
	public def define(name as string, type as string, kind as Kind):
		typeMap.Add(name, type)
		kindMap.Add(name,kind)
		indexMap.Add(name,indexes[kind])
		
		indexes[kind]+=1
	
	public def varCount(kind as Kind) as int:
		return [k.Value for k in kindMap if k.Value == kind].Count

	
	public def kindOf(name as string):
		reuslt as Kind
		if(kindMap.TryGetValue(name,reuslt)):
			return reuslt
		return null
		 
	
	public def typeOf(name as string) as string:
		return typeMap[name]
	
	public def indexOf(name as string) as int:
		return indexMap[name]
		