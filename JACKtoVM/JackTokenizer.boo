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
		while (Char.IsWhiteSpace(nextChar)):// in [char(' '), char('\t'), char('\n'), char('\r')]):
			self.streamReader.Read() //skip the chareceter
			a = self.streamReader.Peek()
			if(a==-1):
				currentType = TokenType.WHITESPACE
				return
			nextChar = a
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
		elif(nextChar == char('/')): //SYMBOL or COMMENT
			self.currentBuffer += Convert.ToChar(self.streamReader.Read())
			nextChar = self.streamReader.Peek()
			if (nextChar == char('/')): // COMMENT LINE
				self.streamReader.ReadLine()//skip the comment line
				currentType = TokenType.COMMENT
			elif (nextChar == char('*')): //COMMENT BLOCK
				self.streamReader.Read() // skips the begining " (should not be included in the token value
				nextChar = self.streamReader.Read()
				while (not (nextChar == char('*') and self.streamReader.Peek()== char('/'))):
					nextChar = self.streamReader.Read()
				self.streamReader.Read()
				currentType = TokenType.COMMENT
			else:
				currentType = TokenType.SYMBOL
		elif(Char.IsLetter(nextChar) or nextChar == char('_')):
			self.currentBuffer += Convert.ToChar(self.streamReader.Read())
			nextChar = self.streamReader.Peek()
			while(Char.IsLetterOrDigit(nextChar) or nextChar == char('_')):
				self.currentBuffer += Convert.ToChar(self.streamReader.Read())
				nextChar = self.streamReader.Peek()
			if(self.currentBuffer in KeyWordConverter.getAllKeywords()):
				currentType = TokenType.KEYWORD
			else:
				currentType = TokenType.IDENTIFIER
		else: //SYMBOL
			self.currentBuffer += Convert.ToChar(self.streamReader.Read())
			currentType = TokenType.SYMBOL
		
		
	public def tokenType() as TokenType:
		return currentType
	
	public def keyWord() as KeyWord:
		if(self.currentType != TokenType.KEYWORD):
			raise "You called keyWord but its not KEYWORD token"
		return KeyWordConverter.toKeyWord(self.currentBuffer)
		
	public def symbol() as string:
		if(self.currentType != TokenType.SYMBOL):
			raise "You called symbol but its not SYMBOL token"
		if(self.currentBuffer == '<'):
			return "&lt;"
		if(self.currentBuffer == '>'):
			return "&gt;"
		if(self.currentBuffer == '"'):
			return "&quot;"
		if(self.currentBuffer == '&'):
			return "&amp;"
		
		return self.currentBuffer
		
	public def identifier() as string:
		if(self.currentType != TokenType.IDENTIFIER):
			raise "You called identifier but its not IDENTIFIER token"
		
		return self.currentBuffer
		
	public def intVal() as int:
		if(self.currentType != TokenType.INT_CONST):
			raise "You called intVal but its not INT_CONST token"
		val = int.Parse(currentBuffer)
		return val
	
	public def stringVal() as string:
		if(self.currentType != TokenType.STRING_CONST):
			raise "You called stringVal but its not STRING_CONST token"
		return currentBuffer
	
	public def Close():
		streamReader.Close()