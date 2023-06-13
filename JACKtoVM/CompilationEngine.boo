namespace JACKtoVM

import System
import System.IO
import System.Xml.Linq
import System.Collections.Generic

class CompilationEngine:
"""Description of CompilationEngine"""
	tokensList as IEnumerator[of XElement]
	outputFile as StreamWriter
	classSt as SymbolTable
	functionSt as SymbolTable
	routineSt as SymbolTable
	
	indent as int

	public def constructor(inputFileName as string, outputFileName as string):	
		self.tokensList = XElement.Load(inputFileName).Elements().GetEnumerator()
		self.tokensList.MoveNext()
		self.outputFile = File.CreateText(outputFileName)
		self.classSt = SymbolTable()
		self.functionSt = SymbolTable()

		
	public def Close():
		outputFile.Close()
	
	private def Write(line as string):
		outputFile.WriteLine("  "*indent + line)
	
	private def IDtoSegmentIndex(id as string) as string:
		if (self.functionSt.kindOf(id) != null):
			return functionSt.kindOf(id) + " " + functionSt.indexOf(id)
		elif (self.classSt.kindOf(id) != null):
			return classSt.kindOf(id) + " " + classSt.indexOf(id)
		else:
			return id// raise "IDENTIFIER " + id + " was not found on symbol tables"
	
	
	public def advance():
	"""Just write the current XElement and advance the tokenList"""
		if (self.checkNext(TokenType.IDENTIFIER,null)):
			self.Write("<identifier> "+ IDtoSegmentIndex(tokensList.Current.Value.Trim())+" </identifier>")		
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
			if(KeyWordConverter.toKeyWord(tokensList.Current.Value.Trim())==shouldBeVal cast KeyWord):
				return true
		if(shouldBeType == TokenType.SYMBOL):
			if(tokensList.Current.Value.Trim()==shouldBeVal):
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
		process(TokenType.IDENTIFIER, null)
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
			type = tokensList.Current.Value
			advance()
		else:
			raise "Unexcepted token: " + tokensList.Current.ToString() + ", should be type!"
		//varName
		if(checkNext(TokenType.IDENTIFIER,null)):
			classSt.define(tokensList.Current.Value, type, kind)
		else:
			raise "No identifier name"
		process(TokenType.IDENTIFIER,null) 
		//(',' varName)*
		while(checkNext(TokenType.SYMBOL,",")):
			advance()
			if(checkNext(TokenType.IDENTIFIER,null)):
				classSt.define(tokensList.Current.Value, type, kind)
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
		//('constructor' | 'function' | 'method')
		if(checkNextMulti(TokenType.KEYWORD, [KeyWord.CONSTRUCTOR, KeyWord.FUNCTION, KeyWord.METHOD])):
			advance()
		//('void' | type)
		if(checkNext(TokenType.KEYWORD,KeyWord.VOID)
				or isType()):
			advance()
		//subroutineName
		process(TokenType.IDENTIFIER,null)
		//'('
		process(TokenType.SYMBOL, "(")
		//parameterList
		compileParameterList()
		//')'
		process(TokenType.SYMBOL, ")")
		//subroutineBody
		compileSubroutineBody()
		
		indent-=1
		self.Write("</subroutineDec>")
	
	public def compileParameterList():
		// ((type varName) (',' type varName)*)?
		self.Write("<parameterList>")
		indent+=1
		//(type varName)
		if(isType()):
			type = tokensList.Current.Value
			advance()
			if(checkNext(TokenType.IDENTIFIER, null)):
				classSt.define(tokensList.Current.Value, type, Kind.ARG)
			process(TokenType.IDENTIFIER,null)
			//(',' type varName)*
			while(checkNext(TokenType.SYMBOL,",")):
				advance()
				if(isType()):
					advance()
				if(checkNext(TokenType.IDENTIFIER, null)):
					classSt.define(tokensList.Current.Value, type, Kind.ARG)
				else:
					raise "Unexcepted token: " + tokensList.Current.ToString() + ", should be type!"
				process(TokenType.IDENTIFIER,null)
		indent-=1
		self.Write("</parameterList>")
		
	public def compileSubroutineBody():
		// '{' varDec* statements '}'
		self.Write("<subroutineBody>")
		indent+=1
		//'{'
		process(TokenType.SYMBOL,"{")
		//varDec*
		while(checkNext(TokenType.KEYWORD,KeyWord.VAR)):
			compileVarDec()
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
			type = tokensList.Current.Value
			advance()
		else:
			raise "Unexcepted token: " + tokensList.Current.ToString() + ", should be type!"
		//varName
		functionSt.define(tokensList.Current.Value,type, Kind.VAR)
		process(TokenType.IDENTIFIER,null)
		//(',' varName)*
		while(checkNext(TokenType.SYMBOL,",")):
			advance()
			functionSt.define(tokensList.Current.Value,type, Kind.VAR)
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
		process(TokenType.IDENTIFIER,null)
		// ('[' expression ']')?
		if(checkNext(TokenType.SYMBOL,"[")):
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
		// ';'
		process(TokenType.SYMBOL,";")
		
		indent-=1
		self.Write("</letStatement>")


	public def compileIf():
		// 'if' '(' expression ')' '{' statements '}' ('else' '{' statements '}')?
		self.Write("<ifStatement>")
		indent+=1
		// 'if'
		process(TokenType.KEYWORD,KeyWord.IF)
		// '('
		process(TokenType.SYMBOL,"(")
		// expression
		compileExpression()
		// ')'
		process(TokenType.SYMBOL,")")
		// '{'
		process(TokenType.SYMBOL,"{")
		//statements
		compileStatements()
		// '}'
		process(TokenType.SYMBOL,"}")
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
			
		indent-=1
		self.Write("</ifStatement>")
		
		
	public def compileWhile():
		// 'while' '(' expression ')' '{' statements '}'
		self.Write("<whileStatement>")
		indent+=1
		
		// 'while'
		process(TokenType.KEYWORD,KeyWord.WHILE)
		// '('
		process(TokenType.SYMBOL,"(")
		// expression
		compileExpression()
		// ')'
		process(TokenType.SYMBOL,")")
		// '{'
		process(TokenType.SYMBOL,"{")
		//statements
		compileStatements()
		// '}'
		process(TokenType.SYMBOL,"}")
		
		indent-=1
		self.Write("</whileStatement>")
	
	
	public def compileDo():
		// 'do' subroutineCall ';'
		self.Write("<doStatement>")
		indent+=1
		process(TokenType.KEYWORD,KeyWord.DO)
		// subroutineCall ->  ID(.ID)? '(' expressionList ')'
		//ID
		process(TokenType.IDENTIFIER,null)
		//(.ID)?
		if(checkNext(TokenType.SYMBOL,".")):
			advance()
			//ID
			process(TokenType.IDENTIFIER,null)
		//'('
		process(TokenType.SYMBOL,"(")
		//expressionList
		compileExpressionList()
		//')'
		process(TokenType.SYMBOL,")")
		//';'
		process(TokenType.SYMBOL,';')
		
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
			advance()
			compileTerm()
			
		indent-=1
		self.Write("</expression>")
		
		
	public def compileTerm():
		// integerConstant | stringConstant | keyWordConstant | varName ('[' expression ']')? | subroutineCall | '(' expression ')' | unaryOp term
		self.Write("<term>")
		indent+=1
		
		//intagerConstant
		if(checkNext(TokenType.INT_CONST,null)):
			advance()
		//stringConstant 
		elif(checkNext(TokenType.STRING_CONST,null)):
			advance()
		// keyWordConstant
		elif(checkNextMulti(TokenType.KEYWORD,[KeyWord.TRUE, KeyWord.FALSE ,KeyWord.NULL ,KeyWord.THIS])):
			advance()
		// varName ('[' expression ']')? | subroutineCall  
		//		<=> 	ID(((.ID)? '(' expressionList ')') | (('[' expression ']')?))
		if(checkNext(TokenType.IDENTIFIER, null)):
		   	//ID
		   	advance()
		   	//('[' expression ']')?
		   	if(checkNext(TokenType.SYMBOL, "[")):
		   		//'['
		   		advance()
		   		//expression
		   		compileExpression()
		   		//']'
		   		process(TokenType.SYMBOL,"]")
	   		//((.ID)? '(' expressionList ')')
		   	else:
		   		//(.ID)?
		   		if(checkNext(TokenType.SYMBOL,".")):
		   			//.
		   			advance()
		   			//ID
		   			process(TokenType.IDENTIFIER,null)
		   		//'(' expressionList ')'
		   		if(checkNext(TokenType.SYMBOL,"(")):
			   		advance()
			   		compileExpressionList()
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
			advance()
			//term
			compileTerm()
		
		indent-=1
		self.Write("</term>")
		
		
	public def compileExpressionList():
		//(expression (',' expression)*)?
		self.Write("<expressionList>")
		indent+=1
		//(expression (',' expression)*)?
		if(isTermStart()):
			//expression
			compileExpression()
			//(',' expression)*
			while(checkNext(TokenType.SYMBOL,",")):
				//','
				advance()
				//expression
				compileExpression()
				
		indent-=1
		self.Write("</expressionList>")