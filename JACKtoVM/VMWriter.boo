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
		
	public def writeArithmetic(op as string, isUnary as bool):
		if(op=="+"):
			outputFile.WriteLine("add")
		if(op=="-" and not isUnary):
			outputFile.WriteLine("sub")
		if(op=="*"):
			outputFile.WriteLine("call Math.multiply 2")
		if(op=="/"):
			outputFile.WriteLine("call Math.divide 2")
		if(op=="&"):
			outputFile.WriteLine("and")
		if(op=="|"):
			outputFile.WriteLine("or")
		if(op=="<"):
			outputFile.WriteLine("lt") //BECAREFUL MAYBE its gt
		if(op==">"):
			outputFile.WriteLine("gt")
		if(op=="="):
			outputFile.WriteLine("eq")
		if(op=="~"):
			outputFile.WriteLine("not")
		if(op=="-" and isUnary):
			outputFile.WriteLine("neg")
		if(not(op in ["+","-","*","/","&","|","<",">","=","~","-"])):
			raise op + " is not vaild command!"
			
			
	public def writeLabel(label as string):
		outputFile.WriteLine("label "+label)
		
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
	
	public def Close():
		outputFile.Close()