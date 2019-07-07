
rule([[ FunctionDeclaration <- FunctionKeyword _ Identifier _ Parameters _ SilentTerminal StartFunctionBody FunctionBody EndFunctionKeyword ]], basic.concat)
table.insert(globalStatements, "FunctionDeclaration")

rule([[ FunctionKeyword <- 'function' ]], 'auto')
table.insert(keywords, "FunctionKeyword")

rule([[ Parameters <- NoParameters / ParameterList ]], basic.first )
rule([[ NoParameters <- (ParametersLParen _ ParametersRParen)? ]], "()" )
rule([[ ParameterList <- ParametersLParen _ SimpleDeclarationList _ ParametersRParen ]], basic.concat )
rule([[ ParametersLParen <- "(" ]], "(")
rule([[ ParametersRParen <- ")" ]], ")")

rule([[ StartFunctionBody <- '' ]], "{\n")
rule([[ FunctionBody <- Skip (!EndFunctionKeyword (ReturnStatement / LocalStatement) Skip)* ]], basic.concat )

rule([[ ReturnStatement <- ReturnKeyword _ Expression _ Terminal ]], basic.concat )
rule([[ ReturnKeyword <- 'return' ]], 'return')

rule([[ EndFunctionKeyword <- 'end' ]], '}')
table.insert(keywords, "EndFunctionKeyword")
