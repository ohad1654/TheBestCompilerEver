namespace JACKtoVM

import System
import System.IO


def main():
	FILE_SIGN = ""
	T_XML_EXTENSION = "T"+FILE_SIGN +".xml"
	XML_EXTENSION = FILE_SIGN +".xml"
	print "-----------------------------"
	print "Hellllllllooooo!!!!!!!!"
	print "Welcome to Best compiler ever"
	print "JACK-->VM"
	print "-----------------------------"
	print "Enter path to directory please: "
	path = Console.ReadLine()
	files = pathToFileInfos(path)

	for file in files:
		inputFileName = file.FullName
		tokensFileName = file.FullName.Replace(".jack",T_XML_EXTENSION)
		
		jackTokenizer = JackTokenizer(inputFileName) //the real name is "Jacky"! :)
		tokensFile = File.CreateText(tokensFileName)
		
		tokensFile.WriteLine("<tokens>")
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
			
		tokensFile.WriteLine("</tokens>")
		tokensFile.Close()
		jackTokenizer.Close()
		print tokensFileName.Replace(T_XML_EXTENSION,XML_EXTENSION)
		compilationEngine = CompilationEngine(tokensFileName, tokensFileName.Replace(T_XML_EXTENSION,XML_EXTENSION))
		compilationEngine.compileClass()
		try:
			//compilationEngine.compileClass()
			pass
		except E:
			compilationEngine.Close()
			print "Bad file: " + tokensFileName
			raise E
		
		compilationEngine.Close()



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
	tag = TokenTypeConverter.toString(tagName)
	val = formatStrToXML(val)
	return String.Format("<{0}> {1} </{0}>", tag, val)

def formatStrToXML(str as string) as string:
	return str.Replace('&',"&amp;").Replace('<',"&lt;").Replace('>',"&gt;").Replace('"',"&quot;")
	


main()
print "Press any key to countinue..."
Console.ReadKey(true)
