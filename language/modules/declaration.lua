

-- note that a declaration does not include a trailing break because we want to use it in function parameters
rule([[ SimpleDeclaration <- AutoType _ Identifier _ AssignOperator _ Expression ]], basic.concat )
rule([[ Assignment <- Identifier _ AssignOperator _ Expression _ Terminal ]], basic.concat )

rule([[ SimpleDeclarationList <- SimpleDeclaration (_ DeclarationSep _ SimpleDeclaration)* ]], basic.concat )
rule([[ DeclarationSep <- ',' ]], ',' )

rule([[ AutoType <- ConstantType / VariableType ]], basic.first )
rule([[ ConstantType <- 'val' ]], 'const auto' )
rule([[ VariableType <- 'var' ]], 'auto' )
table.insert(keywords, "AutoType")

rule([[ AssignOperator <- ':=' ]], "=" )

table.insert(globalStatements, "SimpleDeclaration _ Terminal")
table.insert(localStatements, "SimpleDeclaration _ Terminal")
table.insert(localStatements, "Assignment")
