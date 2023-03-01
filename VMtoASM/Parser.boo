namespace VMtoASM

import System
import System.IO

class Parser:
"""Description of Parser"""
	streamReader as StreamReader
	currentCommand = ""
	
	public def constructor(fileName as string):
		self.streamReader = StreamReader(fileName)
	
	public def hasMoreLines():
		return not streamReader.EndOfStream
	
	public def advance():
		currentCommand = streamReader.ReadLine()
		currentCommand = currentCommand.Trim()
		args = currentCommand.Split(char(' '))
		
	public def getCommandType():
		return CommandType.C_PUSH
		
	public def getArg1():
		return ""
	
	public def getArg2():
		return 0
		

