namespace JACKtoVM

static class KindEnumConverter:
"""Description of KindEnumConverter"""
	
	public def toString(kind as Kind) as string:
		if(kind == Kind.STATIC):
			return "static"
		if(kind == Kind.FIELD):
			return "this"
		if(kind == Kind.VAR):
			return "local"
		if(kind == Kind.ARG):
			return "argument"
		
	

enum Kind:
	STATIC;
	FIELD;
	ARG;
	VAR