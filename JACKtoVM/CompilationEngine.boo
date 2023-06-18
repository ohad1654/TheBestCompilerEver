namespace JACKtoVM

import System
import System.IO
import System.Xml.Linq
import System.Collections.Generic

class CompilationEngine:
"""Description of CompilationEngine"""
	tokensList as IEnumerator[of XElement]
	outputFile as StreamWriter
	indent as int
	
	classSt as SymbolTable
	functionSt as SymbolTable
	vmWriter as VMWriter
	
	ifsCounter as int 		// can marge into one counter  
	whilesCounter as int	// ^^^^^^^^^^^^^^^^^^^^^^^^^^
	
	//information vars
	currentSubRoutine as string
	currentClass as string
	


	public def constructor(inputFileName as string, outputFileName as string):	
		self.tokensList = XElement.Load(inputFileName).Elements().GetEnumerator()
		self.tokensList.MoveNext()
		self.outputFile = File.CreateText(outputFileName)
		self.classSt = SymbolTable()
		self.functionSt = SymbolTable()
		self.vmWriter = VMWriter(outputFileName.Replace(".xml",".vm"))
	
	private def getCurrentToken() as string:
		return tokensList.Current.Value.Trim()
	
	private def getSegment(name as string) as string: //vm
		kind = functionSt.kindOf(name)
		if(kind == null):
			kind = classSt.kindOf(name)
		if(kind == null):
			raise "No such identifier: " + name
		return KindEnumConverter.toString(kind)
		
	private def getIndex(name as string) as int: //vm
		index = functionSt.indexOf(name)
		if(index == -1):
			index = classSt.indexOf(name)
		if(index == -1):
			raise "No such identifier: " + name
		return index
		
	private def getType(name as string) as string: //vm
		type = functionSt.typeOf(name)
		if(type == null):
			type = classSt.typeOf(name)
		if(type == null):
			raise "No such identifier: " + name
		return type
		
	public def Close():
		outputFile.Close()
		vmWriter.Close()
	
	private def Write(line as string):
		outputFile.WriteLine("  "*indent + line)
	
	private def IDtoSegmentIndex(id as string) as string:
		if (self.functionSt.kindOf(id) != null):
			return KindEnumConverter.toString(functionSt.kindOf(id)) + " " + functionSt.indexOf(id)
		elif (self.classSt.kindOf(id) != null):
			return KindEnumConverter.toString(classSt.kindOf(id)) + " " + classSt.indexOf(id)
		else:
			return id// raise "IDENTIFIER " + id + " was not found on symbol tables"
	
	
	public def advance():
	"""Just write the current XElement and advance the tokenList"""
		if (self.checkNext(TokenType.IDENTIFIER,null)):
			self.Write("<identifier> "+ IDtoSegmentIndex(getCurrentToken())+" </identifier>")		
		else: 
			self.Write(tokensList.Current.ToString())
		tokensList.MoveNext()
	
	private def process(shouldBeType as TokenType, shouldBeVal):
	"""Check if the the current XElement is as requierd by the parms,
	   if true- write it and advance. else- rasie an error"""
		if (self.checkNext(shouldBeType, shouldBeVal)):
			advance()
		else:
			raise "Unexcepted token: " + tokensList.Current.ToString()	
		
	
	private def checkNext(shouldBeType as TokenType, shouldBeVal) as bool:
	"""Check if the the current XElement is as requierd by the parms"""
		if(TokenTypeConverter.toTokenType(tokensList.Current.Name.ToString()) != shouldBeType):
			return false
		if(shouldBeVal == null):
			return true
		if(shouldBeType == TokenType.KEYWORD):
			if(KeyWordConverter.toKeyWord(getCurrentToken())==shouldBeVal cast KeyWord):
				return true
		if(shouldBeType == TokenType.SYMBOL):
			if(getCurrentToken()==shouldBeVal):
				return true
		return false

	
	private def checkNextMulti(shouldBeType as TokenType, shouldBeVals as Boo.Lang.List) as bool:
	"""Check if the the current XElement is as requierd by the parms"""
		for val in shouldBeVals:
			if checkNext(shouldBeType,val):
				return true
		return false
		
	private def isType() as bool:
		if(checkNextMulti(TokenType.KEYWORD, [KeyWord.INT,KeyWord.CHAR,KeyWord.BOOLEAN])):
			return true
		if(checkNext(TokenType.IDENTIFIER, null))://className
		   	return true
	   	
		return false
	
	private def isTermStart() as bool:
		//intagerConstant
		if(checkNext(TokenType.INT_CONST,null)):
			return true
		//stringConstant 
		if(checkNext(TokenType.STRING_CONST,null)):
			return true
		// keyWordConstant
		if(checkNextMulti(TokenType.KEYWORD,[KeyWord.TRUE, KeyWord.FALSE ,KeyWord.NULL ,KeyWord.THIS])):
			return true
		//varName|subroutineName 
		if(checkNext(TokenType.IDENTIFIER, null)):
		   	return true 
		//"(" expression ")"
		if(checkNext(TokenType.SYMBOL, "(")):
		   	return true 
		//unaryOp 
		if(checkNext(TokenType.SYMBOL, "-")):
		   	return true 
		if(checkNext(TokenType.SYMBOL, "~")):
		   	return true 
		return false
	
	public def compileClass():
		//'class' className '{' classVarDec* subroutineDec* '}'

		self.Write("<class>")
		indent+=1
		
		// 'class'
		process(TokenType.KEYWORD, KeyWord.CLASS)
		// className
		if (checkNext(TokenType.IDENTIFIER, null)):
			currentClass = getCurrentToken()
			advance()
		else:
			raise "Excpted class name, got: "+getCurrentToken()
		// '{'
		process(TokenType.SYMBOL,"{")
		// classVarDec*
		while (checkNextMulti(TokenType.KEYWORD, [KeyWord.STATIC, KeyWord.FIELD])):
			compileClassVarDec()
		// subroutineDec*
		while (checkNextMulti(TokenType.KEYWORD, [KeyWord.CONSTRUCTOR, KeyWord.FUNCTION, KeyWord.METHOD])):
			compileSubroutine()
		// '}'
		process(TokenType.SYMBOL,"}")
		
		indent-=1
		self.Write("</class>")
	
	public def compileClassVarDec():
		//('static' | 'field') type varName (',' varName)* ';'
		self.Write("<classVarDec>")
		indent+=1
		type as string
		kind as Kind
		//('static' | 'field')
		if(checkNextMulti(TokenType.KEYWORD, [KeyWord.STATIC, KeyWord.FIELD])):
			if(checkNext(TokenType.KEYWORD, KeyWord.STATIC)):
				kind = Kind.STATIC
			else:
				kind = Kind.FIELD
			advance()
		else:
			raise "Unexcepted token: " + tokensList.Current.ToString() +", should be static or field!"
		//type
		if(isType()):
			type = getCurrentToken()
			advance()
		else:
			raise "Unexcepted token: " + tokensList.Current.ToString() + ", should be type!"
		//varName
		if(checkNext(TokenType.IDENTIFIER,null)):
			classSt.define(getCurrentToken(), type, kind)
		else:
			raise "No identifier name"
		process(TokenType.IDENTIFIER,null) 
		//(',' varName)*
		while(checkNext(TokenType.SYMBOL,",")):
			advance()
			if(checkNext(TokenType.IDENTIFIER,null)):
				classSt.define(getCurrentToken(), type, kind)
			else:
				raise "No identifier name"
			process(TokenType.IDENTIFIER,null)
		//';'
		process(TokenType.SYMBOL,';')
		
		indent-=1
		self.Write("</classVarDec>")
		
	public def compileSubroutine():
		// ('constructor' | 'function' | 'method') ('void' | type) subroutineName '(' parameterList ')' subroutineBody
		self.Write("<subroutineDec>")
		indent+=1
		
		functionType as string
		functionSt.reset()
		
		//('constructor' | 'function' | 'method')
		if(checkNextMulti(TokenType.KEYWORD, [KeyWord.CONSTRUCTOR, KeyWord.FUNCTION, KeyWord.METHOD])):
			functionType=getCurrentToken()
			advance()
		//('void' | type)
		if(checkNext(TokenType.KEYWORD,KeyWord.VOID)
				or isType()):
			advance()
		//subroutineName
		self.currentSubRoutine = getCurrentToken() //save what is the currrent compiked subroutine for debugging/print errors
		process(TokenType.IDENTIFIER,null)
		//'('
		process(TokenType.SYMBOL, "(")
		//parameterList
		if functionType == "method":
			functionSt.define("this",currentClass,Kind.ARG) //vm: if it method or constructor we must add 'this' to the symble table
		compileParameterList()
		//')'
		process(TokenType.SYMBOL, ")")
		//subroutineBody
		compileSubroutineBody(functionType)
		
		indent-=1
		self.Write("</subroutineDec>")
	
	public def compileParameterList():
		// ((type varName) (',' type varName)*)?
		self.Write("<parameterList>")
		indent+=1
		//(type varName)
		if(isType()):
			type =  getCurrentToken()
			advance()
			if(checkNext(TokenType.IDENTIFIER, null)):
				functionSt.define(getCurrentToken(), type, Kind.ARG)
			process(TokenType.IDENTIFIER,null)
			//(',' type varName)*
			while(checkNext(TokenType.SYMBOL,",")):
				advance()
				if(isType()):
					advance()
				if(checkNext(TokenType.IDENTIFIER, null)):
					functionSt.define(getCurrentToken(), type, Kind.ARG)
				else:
					raise "Unexcepted token: " + tokensList.Current.ToString() + ", should be type!"
				process(TokenType.IDENTIFIER,null)
		indent-=1
		self.Write("</parameterList>")
		
	public def compileSubroutineBody(functionType as string):
		// '{' varDec* statements '}'
		self.Write("<subroutineBody>")
		indent+=1
		//'{'
		process(TokenType.SYMBOL,"{")
		//varDec*
		while(checkNext(TokenType.KEYWORD,KeyWord.VAR)):
			compileVarDec()
		
		vmWriter.writeFunction(currentClass + "." + currentSubRoutine, functionSt.varCount(Kind.VAR))
		
		if functionType=="constructor":
			vmWriter.writePush("constant", classSt.varCount(Kind.FIELD))
			vmWriter.writeCall("Memory.alloc", 1)
			vmWriter.writePop("pointer", 0)
		elif functionType== "method":
			vmWriter.writePush("argument",0)
			vmWriter.writePop("pointer",0)
		//statements
		compileStatements()
		//'}'
		process(TokenType.SYMBOL,"}")
		indent-=1
		self.Write("</subroutineBody>")
		
		
	public def compileVarDec():
		// 'var' type varName (',' varName)* ';'
		self.Write("<varDec>")
		indent+=1
		type as string
		//'var'
		process(TokenType.KEYWORD,KeyWord.VAR)
		//type
		if(isType()):
			type = getCurrentToken()
			advance()
		else:
			raise "Unexcepted token: " + tokensList.Current.ToString() + ", should be type!"
		//varName
		functionSt.define(getCurrentToken(),type, Kind.VAR)
		process(TokenType.IDENTIFIER,null)
		//(',' varName)*
		while(checkNext(TokenType.SYMBOL,",")):
			advance()
			functionSt.define(getCurrentToken(),type, Kind.VAR)
			process(TokenType.IDENTIFIER,null)
		//';'
		process(TokenType.SYMBOL,';')
		
		indent-=1
		self.Write("</varDec>")
		
		
	public def compileStatements():
		// statement*
		self.Write("<statements>")		
		indent+=1
		// statement*
		flag = true
		while(flag):
			if(checkNext(TokenType.KEYWORD,KeyWord.LET)):
				compileLet()
			elif(checkNext(TokenType.KEYWORD,KeyWord.IF)):
				compileIf()
			elif(checkNext(TokenType.KEYWORD,KeyWord.WHILE)):
				compileWhile()
			elif(checkNext(TokenType.KEYWORD,KeyWord.DO)):
				compileDo()
			elif(checkNext(TokenType.KEYWORD,KeyWord.RETURN)):
				compileReturn()
			else:
				flag = false

		indent-=1
		self.Write("</statements>")


	public def compileLet():
		// 'let' varName ('[' expression ']')? '=' expression ';'
		self.Write("<letStatement>")		
		indent+=1
		// 'let'
		process(TokenType.KEYWORD,KeyWord.LET)
		// varName
		id=""
		if(checkNext(TokenType.IDENTIFIER,null)):
			id = getCurrentToken() //vm: save the varName for later...	
			advance()
		// ('[' expression ']')?
		if(checkNext(TokenType.SYMBOL,"[")):
			raise "Arrays not implomenteded yet!"
			//'['
			advance()
			//expression
			compileExpression()
			//']'
			process(TokenType.SYMBOL,"]")
		// '='
		process(TokenType.SYMBOL,"=")
		// expression
		compileExpression()
		vmWriter.writePop(getSegment(id),getIndex(id)) //vm: save the calculated expression into varName
		// ';'
		process(TokenType.SYMBOL,";")
		
		indent-=1
		self.Write("</letStatement>")


	public def compileIf():
		// 'if' '(' expression ')' '{' statements '}' ('else' '{' statements '}')?
		self.Write("<ifStatement>")
		indent+=1
		
		ifLocalCounter=ifsCounter
		ifsCounter+=1
		// 'if'
		process(TokenType.KEYWORD,KeyWord.IF)
		// '('
		process(TokenType.SYMBOL,"(")
		// expression
		compileExpression()
		vmWriter.writeArithmetic("~",true) // vm: not(the expression)
		// ')'
		process(TokenType.SYMBOL,")")
		
		vmWriter.writeIf("FALSE"+ifLocalCounter) // vm: create lable to jump to if the expression is false
		
		// '{'
		process(TokenType.SYMBOL,"{")
		//statements
		compileStatements()
		vmWriter.writeGoto("ENDIF"+ifLocalCounter) // vm: jump over the ELSE statment.
		// '}'
		process(TokenType.SYMBOL,"}")
		
		vmWriter.writeLabel("FALSE"+ifLocalCounter) // vm: the place to goto if the expression is false
		
		// ('else' '{' statements '}')?
		if(checkNext(TokenType.KEYWORD,KeyWord.ELSE)):
			//'else'
			advance()
			// '{'
			process(TokenType.SYMBOL,"{")
			//statements
			compileStatements()
			// '}'
			process(TokenType.SYMBOL,"}")
			
		vmWriter.writeLabel("ENDIF"+ifLocalCounter) //vm: lable the end of the if statmant
			
		indent-=1
		self.Write("</ifStatement>")
		
		
	public def compileWhile():
		// 'while' '(' expression ')' '{' statements '}'
		self.Write("<whileStatement>")
		indent+=1
		whileLocalCounter=whilesCounter
		vmWriter.writeLabel("WHILE_START"+whileLocalCounter) //vm: lable the start of the while statmant	
		// 'while'
		process(TokenType.KEYWORD,KeyWord.WHILE)
		// '('
		process(TokenType.SYMBOL,"(")
		// expression
		compileExpression()
		vmWriter.writeArithmetic("~",true) // vm: not(the expression)
		// ')'
		process(TokenType.SYMBOL,")")
		
		vmWriter.writeIf("WHILE_END"+whileLocalCounter) // exit the while if the expression is false
		
		// '{'
		process(TokenType.SYMBOL,"{")
		//statements
		compileStatements()
		vmWriter.writeGoto("WHILE_START"+whileLocalCounter)
		// '}'
		process(TokenType.SYMBOL,"}")
		vmWriter.writeLabel("WHILE_END"+whilesCounter) //vm: lable the end of the while statmant
		
		whilesCounter+=1
		indent-=1
		self.Write("</whileStatement>")
	
	
	public def compileDo():
		// 'do' subroutineCall ';'
		self.Write("<doStatement>")
		indent+=1
		
		nArgs = 0
		
		process(TokenType.KEYWORD,KeyWord.DO)
		// subroutineCall ->  ID(.ID)? '(' expressionList ')'
		//ID
		id = ""
		if(checkNext(TokenType.IDENTIFIER,null)):
			id=getCurrentToken()
			if(id=="Screen"):
				a=1
			advance()
		else:
			raise "Excpeted function name, got: "+getCurrentToken()
		//(.ID)?
		if(checkNext(TokenType.SYMBOL,".")):
			advance()
			//ID
			if(checkNext(TokenType.IDENTIFIER,null)):
				try:
					vmWriter.writePush(getSegment(id),getIndex(id)) // vm: push the obj of the method
					id = getType(id)+"."+ getCurrentToken()
					nArgs=nArgs+1 // vm: increas the nArgs by 1
				except e:		//the function is static
					id += "." + getCurrentToken()
				advance()
			else:
				raise "Excpeted method name, got: "+getCurrentToken()
		else:
			//vm: calling a method of current class
			vmWriter.writePush("pointer",0) // vm: push the obj of the method
			id=currentClass+"."+id
			nArgs = nArgs + 1
		//'('
		process(TokenType.SYMBOL,"(")
		//expressionList
		nArgs+=compileExpressionList()		
		//')'
		process(TokenType.SYMBOL,")")
		//';'
		process(TokenType.SYMBOL,';')
		
		vmWriter.writeCall(id,nArgs)
			
		vmWriter.writePop("temp",0) // vm: ignore the return value of the function
		
		indent-=1
		self.Write("</doStatement>")
		
		
	public def compileReturn():
		// 'return' expression? ';'
		self.Write("<returnStatement>")
		indent+=1
		
		// 'return'
		process(TokenType.KEYWORD,KeyWord.RETURN)
		// expression?
		if(isTermStart()):
			compileExpression()
		else:
			vmWriter.writePush("constant",0) //vm: push junk value, becuse we must return something  
		vmWriter.writeReturn() //vm: trivial... :)
		//';'
		process(TokenType.SYMBOL,';')
		
		indent-=1
		self.Write("</returnStatement>")
		
		
	public def compileExpression():
		// term (op term)*
		self.Write("<expression>")
		indent+=1
		// term
		compileTerm()
		// (op term)*
		while(checkNextMulti(TokenType.SYMBOL,["+","-","*","/","&","|","<",">","="])):
			op=getCurrentToken()
			advance()
			compileTerm()
			vmWriter.writeArithmetic(op,false)
			
		indent-=1
		self.Write("</expression>")
		
		
	public def compileTerm():
		// integerConstant | stringConstant | keyWordConstant | varName ('[' expression ']')? | subroutineCall | '(' expression ')' | unaryOp term
		self.Write("<term>")
		indent+=1
		nArgs = 0
		//intagerConstant
		if(checkNext(TokenType.INT_CONST,null)):
			try:
				vmWriter.writePush("constant",int.Parse(getCurrentToken()))
			except:
				raise "Expected to get constant number, but got instead " + getCurrentToken()
			advance()
		//stringConstant 
		elif(checkNext(TokenType.STRING_CONST,null)):
			advance()
		// keyWordConstant
		elif(checkNextMulti(TokenType.KEYWORD,[KeyWord.TRUE, KeyWord.FALSE ,KeyWord.NULL ,KeyWord.THIS])):
			if(checkNext(TokenType.KEYWORD,KeyWord.TRUE)):
				vmWriter.writePush("constant", 1)
				vmWriter.writeArithmetic("-", true)
			if(checkNextMulti(TokenType.KEYWORD,[KeyWord.FALSE,KeyWord.NULL])):
				vmWriter.writePush("constant", 0)
			if(checkNext(TokenType.KEYWORD,KeyWord.THIS)):
				vmWriter.writePush("pointer",0)
			advance()
		// varName ('[' expression ']')? | subroutineCall  
		//		<=> 	ID(((.ID)? '(' expressionList ')') | (('[' expression ']')?))
		elif(checkNext(TokenType.IDENTIFIER, null)):
		   	//ID
		   	id = getCurrentToken() //vm: it's id or id.id2 or id[exp] or id(exp list)
		   	advance()
		   	//('[' expression ']')?
		   	if(checkNext(TokenType.SYMBOL, "[")): //vm: it's id1[exp]
		   		raise "Arrays not implomenteded yet!"
		   		//'['
		   		advance()
		   		//expression
		   		compileExpression()
		   		//']'
		   		process(TokenType.SYMBOL,"]")
	   		//((.ID)? '(' expressionList ')')
		   	else:
		   		//(.ID)?
		   		if(checkNext(TokenType.SYMBOL,".")): //vm: it's id1.id2
		   			//.
		   			advance()
		   			//ID
		   			if(checkNext(TokenType.IDENTIFIER,null)):
		   				try:
		   					vmWriter.writePush(getSegment(id),getIndex(id))
		   					id = getType(id)+"."+getCurrentToken()
		   					nArgs = nArgs + 1
		   				except E:
		   					id += "." + getCurrentToken()
		   					
		   				advance()
		   		elif(checkNext(TokenType.SYMBOL,"(")):
		   			//vm: calling a method of current class
		   			vmWriter.writePush("pointer",0) // vm: push the obj of the method
		   			id=currentClass+"."+id
		   			nArgs = nArgs + 1
		   		else: //it's id1
		   			vmWriter.writePush(getSegment(id),getIndex(id))
		   		//'(' expressionList ')' vm: it's id(exp list) -> subroutine call
		   		if(checkNext(TokenType.SYMBOL,"(")):
			   		advance()
			   		nArgs += compileExpressionList()
			   		vmWriter.writeCall(id,nArgs)
			   		process(TokenType.SYMBOL,")")
			   		
		//"(" expression ")"
		elif(checkNext(TokenType.SYMBOL, "(")):
		   	//"("
		   	advance()
		   	//expression
		   	compileExpression()
		   	//")"
		   	process(TokenType.SYMBOL,")") 	
		//unaryOp term 
		elif(checkNextMulti(TokenType.SYMBOL, ["-","~"])):
			//unaryOp
			unaryOp = getCurrentToken()
			advance()
			//term
			compileTerm()
			//vm unaryOp
			vmWriter.writeArithmetic(unaryOp,true)
			
		
		indent-=1
		self.Write("</term>")
		
		
	public def compileExpressionList() as int: 
		expressionsCounter as int = 0 //vm: needed when calling function-> f(exp1,exp2, exp3) <=> ...call f 3
		//(expression (',' expression)*)?
		self.Write("<expressionList>")
		indent+=1
		//(expression (',' expression)*)?
		if(isTermStart()):
			//expression
			compileExpression()
			expressionsCounter+=1
			//(',' expression)*
			while(checkNext(TokenType.SYMBOL,",")):
				//','
				advance()
				//expression
				compileExpression()
				expressionsCounter+=1
		indent-=1
		
		self.Write("</expressionList>")
		return expressionsCounter