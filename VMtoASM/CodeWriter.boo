namespace VMtoASM

import System
import System.IO

class CodeWriter:
"""Description of CodeWriter"""
	outputFile as StreamWriter
	className as string
	private labelCounter = 0
	
	public def constructor(fileName as string):
		self.outputFile = File.CreateText(fileName)
		self.className = Path.GetFileNameWithoutExtension(fileName)

	
	public def writeArithmetic(command as string):
	"""This function writes an arithmetic command which takes
	   x, y or only y from the stack, makes a calculation on them, and push
	   the result (=>In total, SP=SP-1)
	 
				 		|		| <--SP
				 	 	|-------| 
				    	|   y   |
				    	|-------|
				    	|   x   |
				    	|-------|
				    	|  ...  |
				    	|_______|
	 """
		self.WriteLine("// "+command) //for debugging asm...
		
		// Binary Op - x = x <OP> y ;SP=SP-1
		if command in ["add", "sub", "and","or"]:
			self.WriteLine(self.popToD()) //pop y to D; D = y
			//calc x <OP> y
			self.WriteLine("A = A - 1") // now M = x 
			self.WriteLine("M = M "+self.commandToOp(command)+" D") // M = M <OP> D

		
		//Unary Op - only first arg in the stack: y = <OP>y ; SP=SP
		elif command in ["neg", "not"]:  
			self.WriteLine("@SP")
			self.WriteLine("A=M-1")
			self.WriteLine("M = "+self.commandToOp(command)+"M")// M = <OP>M
			
		
		// Relational Op, first two args in the stack: x,y. Result is Boolean
		elif command in ["eq","lt","gt"]:
			self.WriteLine(self.popToD()) //D = y; SP=SP-1 ; A = @SP
			//D=x-y
			self.WriteLine("A = A - 1") //A->x
			self.WriteLine("D = M - D")
			//jump to IF_TRUE, if x <RELOP> y 
			self.WriteLine("@IF_TRUE"+labelCounter)//-----------┐
			self.WriteLine("D;"+self.relopToJump(command))//    |
			// in case x not <RELOP> y, push false (=0)         |
			self.WriteLine("@SP")//                             |
			self.WriteLine("A = M - 1")// A->x                  |
			self.WriteLine("M=0")//                             |
			self.WriteLine("@IF_FALSE"+labelCounter)//----------╂---┐
			self.WriteLine("0;JMP")//                           |	|
			//											  <-----┘	|
			self.WriteLine("(IF_TRUE" + labelCounter + ")")//		|
			//push true (=-1)										|
			self.WriteLine("@SP")//									|
			self.WriteLine("A = M - 1")// now M=x					|
			self.WriteLine("M = -1")//								|
			//											   <--------┘
			self.WriteLine("(IF_FALSE" + labelCounter + ")")
			
			labelCounter+=1

		else: 
			raise "CodeWriter: Unknown arithmetic command: " + command
		
		
		
	public def writePush(segment as string, index as int):
		self.WriteLine("// push"+" "+segment+" "+index) //for debugging asm...

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
		self.WriteLine("M = M + 1")
		self.WriteLine("A = M - 1")
		self.WriteLine("M = D")

			
			
	public def writePop(segment as string, index as int):
		self.WriteLine("// pop "+segment+" "+index) //for debugging asm...
		//OVERVIEW:
		//			1) Calculate the destantion addres in and store it at R13.
		//			2) Pop the value at the top at the stack and store it in the addres at R13.
		
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
		
		self.WriteLine("@R15")
		self.WriteLine("M = D") // store the dest address at R13
		self.WriteLine(self.popToD())//D = value of the top argument of the stack
		self.WriteLine("@R15")
		self.WriteLine("A = M") // A = the destanenion address
		self.WriteLine("M = D") //store the poped value (D) at the destanenion (A) 		


	public def writeLabel(label as string, fileName as string):
		self.WriteLine("// label:"+" "+label) //for debugging asm...
		self.WriteLine("("+fileName + "." + label +")")


	public def writeGoto(label as string, fileName as string):
		self.WriteLine("// goto"+" "+label) //for debugging asm...
		self.WriteLine("@"+fileName + "." + label)
		self.WriteLine("0;JMP") 
		
	
	public def writeIf(label as string, fileName as string):
		self.WriteLine("// if-goto"+" "+label) //for debugging asm...
		//pop topmost value
		self.WriteLine("@SP")
		self.WriteLine("M=M-1")
		self.WriteLine("A=M")
		self.WriteLine("D=M")
		// Jump to label if not equal to 0
		self.WriteLine("@" + fileName + "." + label)
		self.WriteLine("D;JNE")
	
	
	public def writeFunction(functionName as string, nVars as int):
		self.WriteLine("// fuction "+ functionName + " "+nVars) //for debugging asm...
		self.WriteLine("("+ functionName +")")
		for(int i=0; i<nVars; i++):
			self.WriteLine("init var " + i + "=0")
			self.writePush("constant", 0)
		pass


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
	"""load the address of segment[i] to AD"""
		result = "@"+segmentToSymbol(segment)+"\n"
		result += "D = M\n"
		result += "@"+i+"\n"
		result += "AD = D + A" //AD = segment + i

		return result
	

	private def relopToJump(relopType as string) as string:
	"""Convert command (eq, lt, gt) to jump hack command (JEQ, JLT, JGT)"""
		if relopType == "eq":
			return "JEQ"
		if relopType == "lt":
			return "JLT"
		if relopType == "gt":
			return "JGT"
		raise "Invalid relop: "+relopType
		
		

	private def commandToOp(command as string) as string:
	"""Convert command (add,sub,not etc.) to math operator (+, -, ! etc.)"""
		if command == "add":
			return "+"
		if command == "sub":
			return "-"
		if command == "and":
			return "&"
		if command == "or":
			return "|"
		if command == "not":
			return "!"
		if command == "neg":
			return "-"
		raise "Invalid command: "+command		
		
		
		
	private def popToD() as string:
	"""load the top arg of the stack to D; decrease SP, store at A the new SP"""
		result= "@SP\n"
		result+="M = M - 1\n" //decrease SP because pop...
		result+="A = M\n"
		result+="D = M"
		
		return result
		