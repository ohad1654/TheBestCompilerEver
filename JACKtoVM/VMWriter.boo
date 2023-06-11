namespace JACKtoVM

import System
import System.IO

class VMWriter:
"""Description of VMWriter"""
	outputFile as StreamWriter
	
	public def constructor(fileName as string):
		self.outputFile = File.CreateText(fileName)
		
	public def writePush(segment as string, index as int):
		outputFile.WriteLine("push " + segment + " " + index)
		
	public def writePop(segment as string, index as int):
		outputFile.WriteLine("pop " + segment + " " + index)
		
	public def writeArithmetic(command as string):
		if command not in ["add","sub","neg","eq","gt","lt","and","or","not"]:
			raise command+" is not vaild command!"
		outputFile.WriteLine(command)
			
	public def writeLabel(label as string):
		outputFile.WriteLine(label)
		
	public def writeGoto(lable as string):
		outputFile.WriteLine("goto "+ lable)
		
	public def writeIf(lable as string):
		outputFile.WriteLine("if-goto "+ lable)
	
	public def writeCall(name as string, nVars as int):
		outputFile.WriteLine("call " + name + " " + nVars)
	
	public def writeFunction(name as string, nVars as int):
		outputFile.WriteLine("function " + name + " " + nVars)
	
	public def writeReturn():
		outputFile.WriteLine("return")
	
	