namespace VMtoASM

import System
import System.IO

public def changeExt(oldFileName as string, newExt as string):
	name = Path.GetFileNameWithoutExtension(oldFileName)
	return name + newExt

def main():
	print "-----------------------------"
	print "Hellllllllooooo!!!!!!!!"
	print "Welcome to Best compiler ever"
	print "-----------------------------"
	
	fileName = ""

	//CodeWriter codeWriter = CodeWriter(fileName)
	
	print "filename: "
	path = Console.ReadLine()
	d = DirectoryInfo(path); 
	Files = d.GetFiles("*.vm"); //Getting vm files
	folderName = Path.GetFileName(path)
	
	for file in Files:
		fileName = file.Name
		parser = Parser(fileName)
		codeWriter = CodeWriter(changeExt(fileName, ".asm"))
		while(parser.hasMoreLines()):
			parser.advance()
			type = parser.getCommandType()
			if(type == CommandType.C_ARITHMETIC):
				codeWriter.writeArithmetic(parser.getArg1())
			elif(type in [CommandType.C_POP,CommandType.C_PUSH]):
				codeWriter.writePushPop(type,parser.getArg1(),parser.getArg2())
		
					
main()
print "Press any key to countinue..."
Console.ReadKey(true)