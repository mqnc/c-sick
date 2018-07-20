
#pragma once
#include "customparser.h"
#define RULE(name) p[#name] = [](const SemanticValues& sv)
#define SV const SemanticValues& sv

// $awa /*comment*/ "\"string\"" "easy" 'h' '\\' '\''  R"furz(awa)furz" R"bubi(awa)furz")bubi"$
// unsigned int varname := xxx;
auto test(){return R"(function f[inline] (int a:=xxx) -> (int b:=xxx) := x end;)";}

auto makeGrammar(){return R"(

Start <- nl (GlobalThing)* _

AssignOperator <- ':='

GlobalThing <- VerbatimCpp / GlobalDeclaration

VerbatimCpp <- CppLimiter CppCode* CppLimiter _
CppLimiter <- '$'
CppCode <- CppComment / CppStringLiteral / CppAnything
CppComment <- <CppSingleLineComment / CppMultiLineComment>
CppSingleLineComment <- '//' (!NL .)* NL
CppMultiLineComment <- '/*' (!'*/' .)* '*/'
CppStringLiteral <- <CppCharConstant / CppSimpleString / CppMultiLineString>
CppCharConstant <- '\'' (('\\' .) / .) '\''
CppSimpleString <- '"' (('\\' .) / (!'"' .))* '"'
CppMultiLineString <- 'R"' $delim<[a-zA-Z_0-9]*> '(' (!(')' $delim '"') .)* ')' $delim '"'
CppAnything <- (!CppLimiter .)

GlobalDeclaration <- (SimpleDeclaration / FunctionDeclaration) _

SimpleDeclaration <- Specifier* Declaree (AssignOperator _ Placeholder)? NL
Specifier <- !Declaree Identifier
Declaree <- Identifier (&AssignOperator / &NL)

FunctionDeclaration <- 'function' WS Identifier OptionalSpecifierList OptionalParameters OptionalReturnValues OptionalBody FunctionEnd NL
OptionalSpecifierList <- ('[' _ Identifier* ']' )? _ 
OptionalParameters <- ('(' _ ParameterDeclarationList ')')? _ 
ParameterDeclarationList <- ParameterDeclaration (',' _ ParameterDeclaration)* / _
ParameterDeclaration <- ParameterSpecifier* Parameter (AssignOperator _ Placeholder)?
ParameterSpecifier <- !Parameter Identifier
Parameter <- Identifier (&AssignOperator / &',' / &')')
OptionalReturnValues <- ('->' _ '(' _ ReturnValueList ')')? _
ReturnValueList <- ParameterDeclaration (',' _ ParameterDeclaration)* / _
OptionalBody <- AssignOperator nl (!FunctionEnd .)* 
FunctionEnd <- 'endfunction' / 'end'

Identifier <- <([a-zA-Z_] [a-zA-Z_0-9]* / VerbatimCpp)> _



WS <- <([ \t] / ('...' _ NL))> # definite whitespace
_ <- WS? # optional whitespace
NL <- <([;\n] _)+> # definite new line (consuming all new lines)
nl <- NL? _ # optional new line

Placeholder <- <'x'*> _

)";}




void makeRules(customparser& p){
	


	RULE(CppAnything) {
		return sv.token();
	};
	
	p["CppCode"] = concat;
	p["_"] = concat;
	p["CppSimpleStringCharacter"] = concat;
	p["CppStringEscapedCharacter"] = concat;
	
	
	
	
};

