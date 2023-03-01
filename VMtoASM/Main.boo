namespace VMtoASM

import System
import System.IO

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
		parser = Parser(file.Name)
		while(parser.hasMoreLines()):
			parser.advance()
			type = parser.getCommandType()
			if(type == 
					
main()
print "Press any key to countinue..."
Console.ReadKey(true)