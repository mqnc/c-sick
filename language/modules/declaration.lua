

-- note that a declaration does not include a trailing break because we want to use it in function parameters

rule([[ SimpleDeclaration <- AutoType _ Declaree _ AssignOperator _ Expression ]], basic.concat )
rule([[ Declaree <- Identifier / StructuredBinding ]], basic.concat )
rule([[ StructuredBinding <- StructBindOpen _ IdentifierList _ StructBindClose ]], basic.concat )
rule([[ StructBindOpen <- TupleOpen ]], '[')
rule([[ StructBindClose <- TupleClose ]], ']')

rule([[ Assignment <- Assignee _ AssignOperator _ Expression _ Terminal ]], basic.concat )
rule([[ Assignee <- Identifier / Tie ]], basic.concat )
rule([[ Tie <- TieOpen _ IdentifierList _ TieClose ]], basic.concat )
rule([[ TieOpen <- TupleOpen ]], 'std::tie(')
rule([[ TieClose <- TupleClose ]], ')')

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
