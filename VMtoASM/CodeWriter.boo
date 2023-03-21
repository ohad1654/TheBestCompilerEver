namespace VMtoASM

import System
import System.IO

class CodeWriter:
"""Description of CodeWriter"""
	outputFile as StreamWriter
	className as string
	private relOpLabelCounter = 0
	private functionLabelCounter = 0
	
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
			self.WriteLine("@IF_TRUE"+relOpLabelCounter)//-----------┐
			self.WriteLine("D;"+self.relopToJump(command))//    |
			// in case x not <RELOP> y, push false (=0)         |
			self.WriteLine("@SP")//                             |
			self.WriteLine("A = M - 1")// A->x                  |
			self.WriteLine("M=0")//                             |
			self.WriteLine("@IF_FALSE"+relOpLabelCounter)//----------╂---┐
			self.WriteLine("0;JMP")//                           |	|
			//											  <-----┘	|
			self.WriteLine("(IF_TRUE" + relOpLabelCounter + ")")//		|
			//push true (=-1)										|
			self.WriteLine("@SP")//									|
			self.WriteLine("A = M - 1")// now M=x					|
			self.WriteLine("M = -1")//								|
			//											   <--------┘
			self.WriteLine("(IF_FALSE" + relOpLabelCounter + ")")
			
			relOpLabelCounter+=1

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
		
		self.WriteLine("@R13")
		self.WriteLine("M = D") // store the dest address at R13
		self.WriteLine(self.popToD())//D = value of the top argument of the stack
		self.WriteLine("@R13")
		self.WriteLine("A = M") // A = the destanenion address
		self.WriteLine("M = D") //store the poped value (D) at the destanenion (A) 		


	public def writeLabel(label as string):
		self.WriteLine("// label:"+" "+label) //for debugging asm...
		self.WriteLine("("+className + "." + label +")")


	public def writeGoto(label as string):
		self.WriteLine("// goto"+" "+label) //for debugging asm...
		self.WriteLine("@"+className + "." + label)
		self.WriteLine("0;JMP") 
		
	
	public def writeIf(label as string):
		self.WriteLine("// if-goto"+" "+label) //for debugging asm...
		//pop topmost value
		self.WriteLine("@SP")
		self.WriteLine("M=M-1")
		self.WriteLine("A=M")
		self.WriteLine("D=M")
		// Jump to label if not equal to 0
		self.WriteLine("@" + className + "." + label)
		self.WriteLine("D;JNE")
	
	
	public def writeFunction(functionName as string, nVars as int):
		self.WriteLine("// fuction "+ functionName + " "+nVars) //for debugging asm...
		self.WriteLine("("+ functionName +")")
		self.WriteLine("//init " + nVars + " with 0")
		
		self.WriteLine("@"+nVars)
		self.WriteLine("D=A")
		self.WriteLine("(" + "INIT_BEGIN" + functionLabelCounter+")") //we don't use writeabel cause it intended to write VM labels
		//loop condition - check if nVarse were set to 0
		self.WriteLine("@"+"INIT_END" + functionLabelCounter)
		self.WriteLine("D;JEQ")
		//decrease counter
		self.WriteLine("D=D-1")
		
		//push another 0 (we can't use self.push("constant",0) as it uses D)
		self.WriteLine("@SP")
		self.WriteLine("M=M+1")
		self.WriteLine("A=M-1")
		self.WriteLine("M=0")
		
		//go back to BeginInitLoop (we can't use writeLabel as it add fileName to label name)
		self.WriteLine("@INIT_BEGIN" + functionLabelCounter)
		self.WriteLine("0;JMP")
		self.WriteLine("@"+"INIT_END" + functionLabelCounter)
		
		functionLabelCounter+=1
	
	public def writeCall(functionNmae as string, nArgs as int):
		pass
		
		
	public def writeReturn():
		self.WriteLine("// Return")
		self.WriteLine("D=D")
		//FRAME = LCL  (actually D=LCL)
		self.WriteLine("// FRAME = LCL")
		self.WriteLine("@LCL")
		self.WriteLine("D=M")

		//RET_ADDRESS = *(FRAME-5) <=>we want to save the return adress
		// (which eqauls to *(FRAME-5)) on RAM[13]
		self.WriteLine("// RET_ADDRESS = *(FRAME-5)")
		self.WriteLine("@5")
		self.WriteLine("D=D-A")
		self.WriteLine("A=D")
		self.WriteLine("D=M") //D=*(FRAME-5)
		self.WriteLine("@14") //We already use R13 on PUSH command
		self.WriteLine("M=D")
		
		//*ARG = pop() <=> we save the return value (which is now the
		// on the top of the stack, an ARGS[0]
		self.WriteLine("// *ARG = pop()")
		self.WriteLine("@SP")
		self.WriteLine("M=M-1")
		self.WriteLine("A=M")
		self.WriteLine("D=M")
		self.WriteLine("@ARG")
		self.WriteLine("A=M")
		self.WriteLine("M=D")
		
		//SP = ARG + 1 <=> repositioning SP (just after RETURN VALUE)
		self.WriteLine("// SP = ARG + 1")
		self.WriteLine("@ARG")
		self.WriteLine("D=M+1") //D=*ARG+1
		self.WriteLine("@SP")
		self.WriteLine("M=D")
		
		//restore the value of all remaining segments:
		//THAT=*(FRAME-1)
		self.WriteLine("// THAT=*(FRAME-1)")
		writeSetDFromFrame(-1)
		writeRestoreSegmentFromD("THAT")
		
		//THIS = *(FRAM-2) 
		self.WriteLine("// THIS = *(FRAM-2)")
		writeSetDFromFrame(-2)
		writeRestoreSegmentFromD("THIS")
		
		//ARG = *(FRAM-3)
		self.WriteLine("// ARG = *(FRAM-3)")
		writeSetDFromFrame(-3)
		writeRestoreSegmentFromD("ARG")
		
		//LCL = *(FRAM-4) 
		self.WriteLine("// LCL = *(FRAM-4) ")
		writeSetDFromFrame(-4)
		writeRestoreSegmentFromD("LCL")
		
		//goto RET <=> go back to return adress
		self.WriteLine("// goto RET ")
		self.WriteLine("@R14")
		self.WriteLine("A=M")
		self.WriteLine("0;JMP")
		
	private def writeSetDFromFrame(offset as int):
		//FRAME = LCL  (actually D=LCL)
		self.WriteLine("@LCL")
		self.WriteLine("D=M")

		self.WriteLine("@"+Math.Abs(offset))
		if(offset > 0):
			self.WriteLine("A=D+A")
		else: self.WriteLine("A=D-A")
		self.WriteLine("D=M") //D=*(FRAME+offset)
		
	private def writeRestoreSegmentFromD(segment as string):
		self.WriteLine("@" + segment)
		self.WriteLine("M=D")
		

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
		