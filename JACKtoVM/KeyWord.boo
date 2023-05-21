namespace JACKtoVM

import System

static class KeyWordConverter:
"""Description of KeyWordConverter"""
	public def getAllKeywords():
		result =[]
		for x in KeyWord.GetNames(KeyWord):
			result+=[x.ToLower()]
		return result
	
	public def toString(keyWord as KeyWord) as string:
		return keyWord.ToString().ToLower()
	
	public def toKeyWord(keywordStr as string) as KeyWord:
		// return Enum.Parse(KeyWord,keywordStr)
        if(keywordStr.ToUpper() == "CLASS"):
                return KeyWord.CLASS
        if(keywordStr.ToUpper() == "METHOD"):
                return KeyWord.METHOD
        if(keywordStr.ToUpper() == "FUNCTION"):
                return KeyWord.FUNCTION
        if(keywordStr.ToUpper() == "CONSTRUCTOR"):
                return KeyWord.CONSTRUCTOR
        if(keywordStr.ToUpper() == "INT"):
                return KeyWord.INT
        if(keywordStr.ToUpper() == "BOOLEAN"):
                return KeyWord.BOOLEAN
        if(keywordStr.ToUpper() == "CHAR"):
                return KeyWord.CHAR
        if(keywordStr.ToUpper() == "VOID"):
                return KeyWord.VOID
        if(keywordStr.ToUpper() == "VAR"):
                return KeyWord.VAR
        if(keywordStr.ToUpper() == "STATIC"):
                return KeyWord.STATIC
        if(keywordStr.ToUpper() == "FIELD"):
                return KeyWord.FIELD
        if(keywordStr.ToUpper() == "LET"):
                return KeyWord.LET
        if(keywordStr.ToUpper() == "DO"):
                return KeyWord.DO
        if(keywordStr.ToUpper() == "IF"):
                return KeyWord.IF
        if(keywordStr.ToUpper() == "ELSE"):
                return KeyWord.ELSE
        if(keywordStr.ToUpper() == "WHILE"):
                return KeyWord.WHILE
        if(keywordStr.ToUpper() == "RETURN"):
                return KeyWord.RETURN
        if(keywordStr.ToUpper() == "TRUE"):
                return KeyWord.TRUE
        if(keywordStr.ToUpper() == "FALSE"):
                return KeyWord.FALSE
        if(keywordStr.ToUpper() == "NULL"):
                return KeyWord.NULL
        if(keywordStr.ToUpper() == "THIS"):
                return KeyWord.THIS
    

		
		
		
enum KeyWord:
	CLASS;
	METHOD;
	FUNCTION;
	CONSTRUCTOR;
	INT;
	BOOLEAN;
	CHAR;
	VOID;
	VAR;
	STATIC;
	FIELD;
	LET;
	DO;
	IF;
	ELSE;
	WHILE;
	RETURN;
	TRUE;
	FALSE;
	NULL;
	THIS