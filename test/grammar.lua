
grammar = {}
actions = {}

function rule(r)
	grammar[1 + #grammar] = r
end

rule([[ Start <- nl (GlobalToken)* _ nl ]])

rule([[ AssignOperator <- ':=' ]])
rule([[ Identifier <- <([a-zA-Z_] [a-zA-Z_0-9]* / VerbatimCpp)> _ ]])

rule([[ GlobalToken <- VerbatimCpp / GlobalDeclaration ]])

rule([[ VerbatimCpp <- CppLimiter CppCode* CppLimiter _ ]])
rule([[ CppLimiter <- '$' ]])
rule([[ CppCode <- CppComment / CppStringLiteral / CppAnything ]])
rule([[ CppComment <- <CppSingleLineComment / CppMultiLineComment> ]])
rule([[ CppSingleLineComment <- '//' (!NL .)* NL ]])
rule([[ CppMultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ CppStringLiteral <- <CppCharConstant / CppSimpleString / CppMultiLineString> ]])
rule([[ CppCharConstant <- '\'' (('\\' .) / .) '\'' ]])
rule([[ CppSimpleString <- '"' (('\\' .) / (!'"' .))* '"' ]])
rule([[ CppMultiLineString <- 'R"' $delim<[a-zA-Z_0-9]*> '(' (!(')' $delim '"') .)* ')' $delim '"' ]])
rule([[ CppAnything <- (!CppLimiter .) ]])

rule([[ GlobalDeclaration <- (SimpleDeclaration / FunctionDeclaration) _ ]])

rule([[ SimpleDeclaration <- Specifier* Declaree (AssignOperator _ Placeholder)? NL ]])
rule([[ Specifier <- !Declaree Identifier ]])
rule([[ Declaree <- Identifier (&AssignOperator / &NL) ]])

rule([[ FunctionDeclaration <- 'function' WS Identifier OptionalSpecifierList OptionalParameters OptionalReturnValues OptionalBody FunctionEnd NL ]])
rule([[ OptionalSpecifierList <- ('[' _ Identifier* ']' )? _  ]])
rule([[ OptionalParameters <- ('(' _ ParameterDeclarationList ')')? _  ]])
rule([[ ParameterDeclarationList <- ParameterDeclaration (',' _ ParameterDeclaration)* / _ ]])
rule([[ ParameterDeclaration <- ParameterSpecifier* Parameter (AssignOperator _ Placeholder)? ]])
rule([[ ParameterSpecifier <- !Parameter Identifier ]])
rule([[ Parameter <- Identifier (&AssignOperator / &',' / &')') ]])
rule([[ OptionalReturnValues <- ('->' _ '(' _ ReturnValueList ')')? _ ]])
rule([[ ReturnValueList <- ParameterDeclaration (',' _ ParameterDeclaration)* / _ ]])
rule([[ OptionalBody <- AssignOperator nl (!FunctionEnd .)*  ]])
rule([[ FunctionEnd <- 'end' ]])

rule([[ WS <- <([ \t] / ('...' _ NL))> # definite whitespace ]])
rule([[ _ <- WS? # optional whitespace ]])
rule([[ NL <- <([;\n] _)+> # definite new line (consuming all new lines) ]])
rule([[ nl <- NL? _ # optional new line ]])

rule([[ Placeholder <- <'x'*> _ ]])

function default(params)
    return params.matched
end

pp = pegparser{
	grammar = table.concat(grammar, "\n"),
	actions = actions,
	default = default,
	packrat = true,
	debuglog = true}

result = pp:parse([[
$int main(){}$
]])
print("parsed: ", result)
