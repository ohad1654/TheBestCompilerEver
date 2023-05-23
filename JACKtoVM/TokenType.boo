namespace JACKtoVM
import System

static class TokenTypeConverter:
"""Description of TokenTypeConverter"""
	
	public def toString(tokenType as TokenType) as string:
		if(tokenType == tokenType.INT_CONST):
			return "integerConstant"
		if(tokenType == tokenType.STRING_CONST):
			return "stringConstant"
		
		return tokenType.ToString().ToLower()
	
	public def toTokenType(tokenTypeStr as string) as TokenType:
		if(tokenTypeStr == "integerConstant"):
			return TokenType.INT_CONST
		if(tokenTypeStr == "stringConstant"):
			return TokenType.STRING_CONST
		
		return Enum.Parse(TokenType,tokenTypeStr.ToUpper())
    
	

enum TokenType:
	KEYWORD;
	SYMBOL;
	IDENTIFIER;
	INT_CONST;
	STRING_CONST;
	COMMENT;
	WHITESPACE