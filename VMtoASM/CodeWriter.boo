namespace VMtoASM

import System
import System.IO
		
class CodeWriter:
"""Description of CodeWriter"""
	outputFile as StreamWriter
	className as string
	public def constructor(fileName as string):
		self.outputFile = File.CreateText(fileName)
		self.className = Path.GetFileNameWithoutExtension(fileName)

	//This function writes an arithmetic command which takes
	// x, y from the stack, makes a calculation on them, and push
	//the result (=>In total, SP=SP-1)
	public def writeArithmetic(command as string):
		self.outputFile.WriteLine("// "+command)
		if command == "add": //add first two args in the stack: x,y
			//D=y
			self.outputFile.WriteLine("@SP")
			self.outputFile.WriteLine("A=M-1")
			self.outputFile.WriteLine("D=M")
			//calc sum
			self.outputFile.WriteLine("A=A-1") // now M=x 
			self.outputFile.WriteLine("M=M+D") // M = M + D
			//we change the real value of sp because 
			//"add" takes two args and puts one instead
			self.outputFile.WriteLine("@SP")
			self.outputFile.WriteLine("M=M-1")
		elif command == "sub": //sub last two args in the stack: x,y
			//D=y
			self.outputFile.WriteLine("@SP")
			self.outputFile.WriteLine("A=M-1")
			self.outputFile.WriteLine("D=M")
			//calc sum
			self.outputFile.WriteLine("A=A-1") // now M=x 
			self.outputFile.WriteLine("M=M-D") // M = M - D
			//we change the real value of sp because 
			//"add" takes two args and puts one instead
			self.outputFile.WriteLine("@SP")
			self.outputFile.WriteLine("M=M-1")
		else: raise "CodeWriter: Unknown arithmetic command: " + command
			
	public def writePushPop(command as CommandType, segment as string, index as int):
		self.outputFile.WriteLine("// "+command+" "+segment+" "+index)
		if command==CommandType.C_PUSH:
			if segment in ["local", "argument", "this", "that"]: //group 1
				self.outputFile.Write(loadSegmentToD(segment,index)) // D = RAM[segment+index]
			
			elif segment == "temp":	//group 2
				self.outputFile.WriteLine("@5") //temp start (temp variables are saved on RAM[5-12])
				self.outputFile.WriteLine("D = A")
				self.outputFile.WriteLine("@"+index)
				self.outputFile.WriteLine("A = A + D")
				self.outputFile.WriteLine("D = M") //D = RAM[5+index]
			elif segment == "static": //group 3
				self.outputFile.WriteLine("@"+self.className+"."+index)
				self.outputFile.WriteLine("D = M") //D = RAM[className.index]
			elif segment == "pointer": //group 4
				if index == 0:
					self.outputFile.WriteLine("@THIS")					
					self.outputFile.WriteLine("D = M") //D = RAM[THIS]
				elif index == 1:
					self.outputFile.WriteLine("@THAT")					
					self.outputFile.WriteLine("D = M") //D = RAM[THAT]
				else:
					raise "Invalid index, index must be 0 or 1"
			elif segment == "constant": //group 5
					self.outputFile.WriteLine("@"+index)
					self.outputFile.WriteLine("D = A") //D = index
			else:
				raise "Unknown segment name: "+segment
			//push D
			self.outputFile.WriteLine("@SP")
			self.outputFile.WriteLine("A = M")
			self.outputFile.WriteLine("M = D")
			self.outputFile.WriteLine("@SP")
			self.outputFile.WriteLine("M = M + 1")
			
		elif command == CommandType.C_POP:
			pass
		
	public def close():
		self.outputFile.Close()
	
	private def segmentToSymbol(segment as string) as string:
		if segment == "local":
			return "LCL"
				
		if segment == "argument":
			return "ARG"
		
		if segment == "this":
			return "THIS"
	
		if segment == "that":
			return "THAT"
		raise "CodeWriter: Unknown segment name: " + segment
	
	
	private def loadSegmentToD(segment as string, i as int) as string:
	"""load the value at segment[i] to D"""
		result = "@"+segmentToSymbol(segment)+"\n"
		result += "D = M\n"
		result += "@" + i + "\n"
		result += "A = D + A\n" //A = segment + i
		result += "D = M\n"
		
		return result