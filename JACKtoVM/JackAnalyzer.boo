namespace JACKtoVM

import System
import System.IO


def main():
	print "-----------------------------"
	print "Hellllllllooooo!!!!!!!!"
	print "Welcome to Best compiler ever"
	print "-----------------------------"
	print "Enter path to directory please: "
	path = Console.ReadLine()
	files = pathToFileInfos(path)
	
	for file in files:
		inputFileName = file.FullName
		tokensFileName = Path.ChangeExtension(file.FullName,".xml")
		
		jackTokenizer = JackTokenizer(inputFileName) //the real name is "Jacky"! :)
		tokensFile = File.CreateText(tokensFileName)
		while(jackTokenizer.hasMoreTokens()):
			jackTokenizer.advance()
			
			
			
		
		
		
		
		
		compilationEngine = CompilationEngine(inputFileName, tokensFileName)
		compilationEngine.compileClass()			



def pathToFileInfos(path as string) as (FileInfo): 
	Files as (FileInfo)
	if (Path.GetExtension(path)==".jack"):
		Files= [FileInfo(path)].ToArray(FileInfo)
	elif Path.GetExtension(path)=="": //path is directory
		d = DirectoryInfo(path);	
		Files = d.GetFiles("*.jack"); //Getting all .jack files
	else:
		raise "Invalid path or file type"
	
	return Files
	





main()
print "Press any key to countinue..."
Console.ReadKey(true)
