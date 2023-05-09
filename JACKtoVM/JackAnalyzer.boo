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
		
		tokensFile.WriteLine("<Tokens>")
		while(jackTokenizer.hasMoreTokens()):
			jackTokenizer.advance()
			tokenType = jackTokenizer.tokenType()
			if(tokenType == TokenType.KEYWORD):
				keyword = jackTokenizer.keyWord()
				tokensFile.WriteLine(createTag(tokenType,KeyWordConverter.toString(keyword)))
			elif(tokenType == TokenType.SYMBOL):
				symbol = jackTokenizer.symbol()
				tokensFile.WriteLine(createTag(tokenType, symbol.ToString()))
			elif(tokenType == TokenType.INT_CONST):
				num = jackTokenizer.intVal()
				tokensFile.WriteLine(createTag(tokenType, num.ToString()))
			elif(tokenType == TokenType.STRING_CONST):
				str = jackTokenizer.stringVal()
				tokensFile.WriteLine(createTag(tokenType, str))
			elif(tokenType == TokenType.IDENTIFIER):
				varName = jackTokenizer.identifier()
				tokensFile.WriteLine(createTag(tokenType, varName)) 
		tokensFile.WriteLine("</Tokens>")
		tokensFile.Close()
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
	


def createTag(tagName as TokenType, val as string) as string:
	return String.Format("<{0}> {1} </{0}>", tagName.ToString().ToLower(), val)

main()
print "Press any key to countinue..."
Console.ReadKey(true)
