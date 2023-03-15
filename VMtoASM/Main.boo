namespace VMtoASM

import System
import System.IO

public def changeExt(oldFileName as string, newExt as string):
	pathWithoutFileName = Path.GetDirectoryName(oldFileName)
	fileName = Path.GetFileNameWithoutExtension(oldFileName)
	result = pathWithoutFileName + "\\" + fileName + newExt
	return result

def main():
	print "-----------------------------"
	print "Hellllllllooooo!!!!!!!!"
	print "Welcome to Best compiler ever"
	print "-----------------------------"
	print "Enter path to directory please: "
	path = Console.ReadLine()
	d = DirectoryInfo(path); 
	Files = d.GetFiles("*.vm"); //Getting vm files
	
	for file in Files:
		fullPathToFile = file.FullName
		fileName = Path.GetFileNameWithoutExtension(fullPathToFile)
		parser = Parser(fullPathToFile)
		codeWriter = CodeWriter(changeExt(fullPathToFile, ".asm"))
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
				codeWriter.writeLabel(parser.getArg1(), fileName)
			elif(type == CommandType.C_GOTO):
				codeWriter.writeGoto(parser.getArg1(), fileName)
			elif(type == CommandType.C_IF):
				codeWriter.writeIf(parser.getArg1(), fileName)
			elif(type == CommandType.C_FUNCTION):
				codeWriter.writeFunction(parser.getArg1(), parser.getArg2())
		codeWriter.close()
			
					
main()
print "Press any key to countinue..."
Console.ReadKey(true)