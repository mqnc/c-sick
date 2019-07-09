
rule([[ FunctionDeclaration <- FunctionKeyword _ Identifier _ Parameters _ SilentTerminal StartFunctionBody FunctionBody EndFunctionKeyword ]], basic.concat)
table.insert(globalStatements, "FunctionDeclaration")

rule([[ FunctionKeyword <- 'function' ]], 'auto')
table.insert(keywords, "FunctionKeyword")

rule([[ Parameters <- ParameterList / NoParameters ]], basic.first )
rule([[ NoParameters <- (ParametersLParen _ ParametersRParen)? ]], "()" )
rule([[ ParameterList <- ParametersLParen _ ParameterDeclarationList _ ParametersRParen ]], basic.concat )
rule([[ ParametersLParen <- "(" ]], "(")
rule([[ ParametersRParen <- ")" ]], ")")

rule([[ ParameterDeclaration <- ParameterType _ Identifier _ AssignOperator _ Expression ]], "{1}{2} decltype({7}) {3}{4}{5}{6}{7}")
rule([[ ParameterDeclarationList <- ParameterDeclaration (_ DeclarationSep _ ParameterDeclaration)* ]], basic.concat )

rule([[ ParameterType <- ConstantParameter / VariableParameter ]], basic.first )
rule([[ ConstantParameter <- 'val' ]], 'const' )
rule([[ VariableParameter <- 'var' ]], '' )

rule([[ StartFunctionBody <- '' ]], "{\n")
rule([[ FunctionBody <- Skip (!EndFunctionKeyword (ReturnStatement / LocalStatement) Skip)* ]], basic.concat )

rule([[ ReturnStatement <- ReturnKeyword _ Assigned _ Terminal ]], basic.concat )
rule([[ ReturnKeyword <- 'return' ]], 'return')

rule([[ EndFunctionKeyword <- 'end' ]], '}')
table.insert(keywords, "EndFunctionKeyword")
