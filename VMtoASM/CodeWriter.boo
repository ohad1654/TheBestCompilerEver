namespace VMtoASM

import System
import System.IO
		
class CodeWriter:
"""Description of CodeWriter"""
	outputFile as StreamWriter 
	public def constructor(fileName as string):
		self.outputFile = StreamWriter(fileName)

	public def writeArithmetic(command as string):
		self.outputFile.WriteLine("// "+command)
			
	public def writePushPop(command as CommandType, segment as string, index as int):
		self.outputFile.WriteLine("// "+command+" "+segment+" "+index)
		if command==CommandType.C_PUSH:
			self.outputFile.Write(loadSegmentToD(segment,index))
			
			//push D
			self.outputFile.WriteLine("@sp")
			self.outputFile.WriteLine("A = M")
			self.outputFile.WriteLine("M = D")
			self.outputFile.WriteLine("@sp")
			self.outputFile.WriteLine("M = M + 1")

				
			
		
	public def close():
		self.outputFile.Close()
	
	
	private def loadSegmentToD(segment as string, i as int) as string:
		result = ""
		if segment == "local":
			result+="@LCL\n"
				
		if segment == "argument":
			result+="@ARG\n"
		
		if segment == "this":
			result+="@THIS\n"
	
		if segment == "that":
			result+="@THAT\n"
		
		result += "D = M\n"
		result += "@" + i + "\n"
		result += "A = D + A\n"
		result += "D = M\n"
		
		return result