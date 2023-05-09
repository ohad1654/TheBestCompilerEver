namespace JACKtoVM

import System
import System.IO

class JackTokenizer:
"""Description of JackTokenizer"""
	streamReader as StreamReader
	currentType as TokenType
	currentBuffer as string
	public def constructor(fileName as string):
		self.streamReader = StreamReader(fileName)
	
	public def hasMoreTokens() as bool:
		return not streamReader.EndOfStream
	
	public def advance():
		self.currentBuffer= ""
		nextChar = Convert.ToChar(self.streamReader.Peek())
		if(nextChar == -1): return
		while (nextChar in [char(' '), char('\t'), char('\n'), char('\r')]):
			self.streamReader.Read() //skip the chareceter
			nextChar = Convert.ToChar(self.streamReader.Peek())
		if(Char.IsDigit(nextChar)):	//INT_CONST
			while (Char.IsDigit(nextChar)): 
				self.currentBuffer += Convert.ToChar(self.streamReader.Read())
				a = self.streamReader.Peek()
				if(a == -1):
					return
				nextChar = a	
			currentType = TokenType.INT_CONST
			return
		elif(nextChar == char('"')): //STRING_CONST
			self.streamReader.Read() // skips the begining " (should not be included in the token value
			nextChar = self.streamReader.Peek()
			while (nextChar != char('"')):
				self.currentBuffer += Convert.ToChar(self.streamReader.Read())
				nextChar = self.streamReader.Peek()
			self.streamReader.Read() // skips the ending "
			currentType = TokenType.STRING_CONST
			return
		elif(nextChar == char('/')): //SYMBOL
			self.currentBuffer += Convert.ToChar(self.streamReader.Read())
			nextChar = self.streamReader.Peek()
			if (nextChar == char('/')): // COMMENT
					self.streamReader.ReadLine()//skip the comment line
				currentType = TokenType.COMMENT
		
	public def tokenType() as TokenType:
		return currentType
	
	public def keyWord() as KeyWord:
		pass
		
	public def symbol() as char:
		pass
		
	public def identifier() as string:
		pass
		
	public def intVal() as int:
		if(self.currentType != TokenType.INT_CONST):
			raise "You called intVal but it it snnot INT_CONST command"
		val = int.Parse(currentBuffer)
		return val
	
	public def stringVal() as string:
		return currentBuffer
	
	public def Close():
		streamReader.Close()