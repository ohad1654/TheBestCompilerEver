namespace VMtoASM

import System
import System.IO

class Parser:
"""Description of Parser"""
	ARITHEMETIC_COMMANDS = ["add","sub","neg","eq","gt","lt","and","or","not"]
	streamReader as StreamReader
	currentCommand = ""
	commandType as CommandType
	arg1 = ""
	arg2 = 0
	
	public def constructor(fileName as string):
		self.streamReader = StreamReader(fileName)
	
	public def close():
		self.streamReader.Close()
	
	public def hasMoreLines():
		return not streamReader.EndOfStream
	
	public def advance():
		currentCommand = streamReader.ReadLine()
		currentCommand = currentCommand.Trim()
		args = currentCommand.Split(char(' '))
		
		//set commandType
		if(args[0] == "//"):
			commandType = CommandType.COMMENT
		elif(args[0] in ARITHEMETIC_COMMANDS):
			commandType = CommandType.C_ARITHMETIC
		elif(args[0] == "push"):
				commandType = CommandType.C_PUSH
		elif(args[0] == "pop"):
			commandType = CommandType.C_POP	
		elif(args[0] == "if"):
			commandType = CommandType.C_IF
		elif(args[0] == ""):
			commandType = CommandType.WHITELINE
		else:
			raise "Unknown command Type: " + currentCommand
		
		//set arg1 and arg2
		arg1 = ""
		arg2 = 0
		if(commandType == CommandType.C_ARITHMETIC):
			arg1 = args[0]
		elif(commandType in [CommandType.C_PUSH, CommandType.C_POP, CommandType.C_FUNCTION, CommandType.C_CALL]):
			arg1 = args[1]
			ok = int.TryParse(args[2],arg2)
			if(not ok):
				print "-----arg2 of the command: " + currentCommand + " is making troublesss"		
		
		
			
	public def getCommandType():
		return commandType
		
	public def getArg1():
		return arg1
	
	public def getArg2():
		return arg2
		

