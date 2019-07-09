

-- note that a declaration does not include a trailing break because we want to use it in function parameters

rule([[ SimpleDeclaration <- AutoType _ Declaree _ AssignOperator _ Assigned ]], basic.concat )
rule([[ Declaree <- StructuredBinding / Identifier ]], basic.concat )
rule([[ StructuredBinding <- StructBindOpen _ IdentifierListMulti _ StructBindClose ]], basic.concat )
rule([[ StructBindOpen <- '' ]], '[')
rule([[ StructBindClose <- '' ]], ']')

rule([[ Assignment <- Assignee _ AssignOperator _ Assigned _ Terminal ]], basic.concat )
rule([[ Assignee <- Tie / Identifier ]], basic.concat )
rule([[ Tie <- IdentifierListMulti ]], 'std::tie({1})' )

rule([[ Assigned <- Tuple / Expression ]], basic.concat )
rule([[ Tuple <- ExpressionListMulti ]], 'std::make_tuple({1})' )

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
