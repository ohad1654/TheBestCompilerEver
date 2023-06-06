namespace VMtoASM

import System
import System.IO

def main():
	print "-----------------------------"
	print "Hellllllllooooo!!!!!!!!"
	print "Welcome to Best compiler ever"
	print "VM-->ASM"
	print "-----------------------------"
	print "Enter path to directory please: "
	path = Console.ReadLine()
	Files as (FileInfo)
	if (Path.GetExtension(path)==".vm"):
		Files= [FileInfo(path)].ToArray(FileInfo)
		codeWriter = CodeWriter(Path.ChangeExtension(path,".asm"), false)
	elif Path.GetExtension(path)=="":// path is directory
		d = DirectoryInfo(path);	
		Files = d.GetFiles("*.vm"); //Getting all .vm files
		codeWriter = CodeWriter(d.FullName + "\\" + d.Name + ".asm", true)
	else:
		raise "Invalid path or file type"
	
	for file in Files:
		fullPathToFile = file.FullName
		fileName=Path.GetFileNameWithoutExtension(file.Name)
		codeWriter.setFileName(fileName)
		parser = Parser(fullPathToFile)
		while(parser.hasMoreLines()):
			parser.advance()
			type = parser.getCommandType()
			print type + ": "+parser.getArg1()+", " + parser.getArg2() 
			if(type == CommandType.COMMENT):
				pass
			elif(type == CommandType.C_ARITHMETIC):
				//print type + ": " + parser.getArg1()
				codeWriter.writeArithmetic(parser.getArg1())
			elif(type == CommandType.C_POP):
				//print type + ": "+parser.getArg1()+", " + parser.getArg2()
				codeWriter.writePop(parser.getArg1(),parser.getArg2())
			elif(type == CommandType.C_PUSH):
				//print type + ": "+parser.getArg1()+", " + parser.getArg2()
				codeWriter.writePush(parser.getArg1(),parser.getArg2())
			elif(type == CommandType.C_LABEL):
				codeWriter.writeLabel(parser.getArg1())
			elif(type == CommandType.C_GOTO):
				codeWriter.writeGoto(parser.getArg1())
			elif(type == CommandType.C_IF):
				codeWriter.writeIf(parser.getArg1())
			elif(type == CommandType.C_FUNCTION):
				codeWriter.writeFunction(parser.getArg1(), parser.getArg2())
			elif(type == CommandType.C_RETURN):
				codeWriter.writeReturn()
			elif(type == CommandType.C_CALL):
				codeWriter.writeCall(parser.getArg1(), parser.getArg2())
	codeWriter.close()
			
					
main()
print "Press any key to countinue..."
Console.ReadKey(true)