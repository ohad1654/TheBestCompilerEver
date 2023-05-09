namespace JACKtoVM

import System

class JackTokenizer:
"""Description of JackTokenizer"""
	streamReader as StreamReader
	
	public def constructor(fileName as string):
		self.streamReader = StreamReader(fileName)
	
	public def hasMoreTokens() as bool:
		return return not streamReader.EndOfStream
	
	public def advance():
		
		
	public def tokenType() as TokenType:
		pass
	
	public def keyWord() as KeyWord:
		pass
		
	public def symbol() as char:
		pass
		
	public def identifier() as string:
		pass
		
	public def intVal() as int:
		pass
	
	public def stringVal() as string:
		pass
	
	public def Close():
		streamReader.Close()