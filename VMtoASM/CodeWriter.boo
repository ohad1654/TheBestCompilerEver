namespace VMtoASM

import System
import System.IO
		
class CodeWriter:
"""Description of CodeWriter"""
	outputFile as StreamWriter
	className as string
	labelCounter = 0
	public def constructor(fileName as string):
		self.outputFile = File.CreateText(fileName)
		self.className = Path.GetFileNameWithoutExtension(fileName)

	//This function writes an arithmetic command which takes
	// x, y from the stack, makes a calculation on them, and push
	//the result (=>In total, SP=SP-1)
	public def writeArithmetic(command as string):
		self.WriteLine("// "+command)
		if command == "add": //add first two args in the stack: x,y
			//D=y
			self.WriteLine("@SP")
			self.WriteLine("A=M-1")
			self.WriteLine("D=M")
			//calc sum
			self.WriteLine("A=A-1") // now M=x 
			self.WriteLine("M=M+D") // M = M + D
			//we change the real value of sp because 
			//"add" takes two args and puts one instead
			self.WriteLine("@SP")
			self.WriteLine("M=M-1")
		elif command == "sub": //sub last two args in the stack: x,y
			//D=y
			self.WriteLine("@SP")
			self.WriteLine("A=M-1")
			self.WriteLine("D=M")
			//calc sum
			self.WriteLine("A=A-1") // now M=x 
			self.WriteLine("M=M-D") // M = M - D
			//we change the real value of sp because 
			//"add" takes two args and puts one instead
			self.WriteLine("@SP")
			self.WriteLine("M=M-1")
		elif command == "neg": //
			//D=x
			self.WriteLine("@SP")
			self.WriteLine("A=M-1")
			self.WriteLine("M=-M")
		elif command in ["eq","lt","gt"]:
			//D=y
			self.WriteLine("@SP")
			self.WriteLine("A=M-1")
			self.WriteLine("D=M")
			//D=y-x
			self.WriteLine("A=A-1")
			self.WriteLine("D=D-M")
			//jump to IFTRUE, if x equal y
			self.WriteLine("@IFTRUE"+labelCounter)
			self.WriteLine("D;"+self.relopToJump(command))
			// in case x not equal y, push false (0)
			self.WriteLine("@SP")
			self.WriteLine("A=M-1")
			self.WriteLine("A=A-1")//A->x
			self.WriteLine("M=0")
			self.WriteLine("@IF_FALSE"+labelCounter)
			self.WriteLine("JMP")
			self.WriteLine("(IF_TRUE" + labelCounter + ") //label")
			self.WriteLine("@SP")
			self.WriteLine("A=M-1")
			self.WriteLine("A=A-1")
			self.WriteLine("M=-1")
			self.WriteLine("(IF_FALSE" + labelCounter + ") //label")
			self.WriteLine("@SP")
			self.WriteLine("M=M-1")
			
		
		else: raise "CodeWriter: Unknown arithmetic command: " + command
			
	public def writePushPop(command as CommandType, segment as string, index as int):
		self.WriteLine("// "+command+" "+segment+" "+index)
		if command==CommandType.C_PUSH:
			if segment in ["local", "argument", "this", "that"]: //group 1
				self.WriteLine(loadSegmentToAD(segment,index)) // A = segment+index
				self.WriteLine("D = M") //D = RAM[segment+index]
			
			elif segment == "temp":	//group 2
				self.WriteLine("@5") // 5=temp start (temp variables are saved on RAM[5-12])
				self.WriteLine("D = A")
				self.WriteLine("@"+index)
				self.WriteLine("A = A + D")
				self.WriteLine("D = M") //D = RAM[5+index]
				
			elif segment == "static": //group 3
				self.WriteLine("@"+self.className+"."+index)
				self.WriteLine("D = M") //D = RAM[className.index]
				
			elif segment == "pointer": //group 4
				if index == 0:
					self.WriteLine("@THIS")					
					self.WriteLine("D = M") //D = RAM[THIS]
				elif index == 1:
					self.WriteLine("@THAT")					
					self.WriteLine("D = M") //D = RAM[THAT]
				else:
					raise "Invalid index, index must be 0 or 1"
				
			elif segment == "constant": //group 5
					self.WriteLine("@"+index)
					self.WriteLine("D = A") //D = index
			else:
				raise "Unknown segment name: "+segment
			
			//push D
			self.WriteLine("@SP")
			self.WriteLine("A = M")
			self.WriteLine("M = D")
			self.WriteLine("@SP")
			self.WriteLine("M = M + 1")
			
		elif command == CommandType.C_POP:
			//OVERVIEW:
			//			1) Calculate the destantion addres in D.
			//			2) store D at R13
			//			3) Pop the value at the top at the stack and store it in the addres at R13.
			
			if segment in ["local", "argument", "this", "that"]: //group 1
				self.WriteLine(loadSegmentToAD(segment,index)) // D = segment+index
			
			elif segment == "temp":	//group 2
				self.WriteLine("@5") // 5=temp start (temp variables are saved on RAM[5-12])
				self.WriteLine("D = A")
				self.WriteLine("@"+index)
				self.WriteLine("D = A + D") // D = 5+index
				
			elif segment == "static": //group 3
				self.WriteLine("@"+self.className+"."+index)
				self.WriteLine("D = A") //D = className.index
				
			elif segment == "pointer": //group 4
				if index == 0:
					self.WriteLine("@THIS")					
					self.WriteLine("D = A") //D = THIS
				elif index == 1:
					self.WriteLine("@THAT")					
					self.WriteLine("D = A") //D = RAM[THAT]
				else:
					raise "Invalid index, index must be 0 or 1"

				
			elif segment == "constant": //group 5
				raise "'constant' is not allowed after 'pop'"
			else:
				raise "Unknown segment name: "+segment
			
			self.WriteLine("@R13")
			self.WriteLine("M = D") // store the dest address at R13
			self.WriteLine("@SP")
			self.WriteLine("M = M - 1") // decreas SP because pop..
			self.WriteLine("A = M") 
			self.WriteLine("D = M")  //D = value of the top argument of the stack
			self.WriteLine("@R13")
			self.WriteLine("A = M") // A = the destanenion address
			self.WriteLine("M = D") //store the poped value (D) at the destanenion (A) 
			
			

	public def close():
		self.outputFile.Close()
	
	
	
	private def WriteLine(line as string):
		self.outputFile.WriteLine(line)
		
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
	
	
	private def loadSegmentToAD(segment as string, i as int) as string:
	"""load the address of segment[i] to A"""
		result = "@"+segmentToSymbol(segment)+"\n"
		result += "D = M\n"
		result += "@"+i+"\n"
		result += "AD = D + A" //AD = segment + i

		return result
	
	private def relopToJump(relopType as string) as string:
		if relopType == "eq":
			return "JEQ"
		if relopType == "lt":
			return "JLT"
		if relopType == "gt":
			return "JGT"
		raise "Invalid relop: "+relopType
		
		
		