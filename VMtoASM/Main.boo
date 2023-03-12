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
		print fullPathToFile
		parser = Parser(fullPathToFile)
		codeWriter = CodeWriter(changeExt(fullPathToFile, ".asm"))
		while(parser.hasMoreLines()):
			parser.advance()
			type = parser.getCommandType()
			if(type == CommandType.COMMENT):
				print("COMMMENT LINE...")
			elif(type == CommandType.C_ARITHMETIC):
				print type + ": " + parser.getArg1()
				codeWriter.writeArithmetic(parser.getArg1())
			elif(type in [CommandType.C_POP,CommandType.C_PUSH]):
				print type + ": "+parser.getArg1()+", " + parser.getArg2()
				codeWriter.writePushPop(type,parser.getArg1(),parser.getArg2())
		codeWriter.close()
			
					
main()
print "Press any key to countinue..."
Console.ReadKey(true)