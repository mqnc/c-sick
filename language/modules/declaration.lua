

rule([[ SimpleDeclaration <- SimpleInitializedDeclaration / SimpleDefaultDeclaration ]], basic.concat )

rule([[ SimpleInitializedDeclaration <- ConstSpecifier InsertAuto _ SimpleDeclaree _ AssignOperator _ Assigned _ Terminal ]], basic.concat )
rule([[ SimpleDeclaree <- StructuredBinding / Identifier ]], basic.concat )
rule([[ StructuredBinding <- StructBindOpen _ IdentifierListMulti _ StructBindClose ]], basic.concat )
rule([[ StructBindOpen <- '' ]], '[')
rule([[ StructBindClose <- '' ]], ']')

rule([[ SimpleDefaultDeclaration <- ConstSpecifier InsertAuto _ SimpleDeclaree _ TypeDeclareOperator _ TypeDefaultCaller _ Terminal ]], basic.concat )
rule([[ TypeDefaultCaller <- Identifier ]], '{1}()')

rule([[ Assignment <- Assignee _ AssignOperator _ Assigned _ Terminal ]], basic.concat )
rule([[ Assignee <- AssigneeTie / Identifier ]], basic.concat )
rule([[ AssigneeTie <- IdentifierListMulti ]], 'std::tie({1})' )

rule([[ Assigned <- AssignedTuple / Expression ]], basic.concat )
rule([[ AssignedTuple <- ExpressionListMulti ]], 'std::make_tuple({1})' )

rule([[ SimpleDeclarationList <- SimpleDeclaration (_ DeclarationSep _ SimpleDeclaration)* ]], basic.concat )
rule([[ DeclarationSep <- ',' ]], ',' )

rule([[ ConstSpecifier <- ConstantType / VariableType ]], basic.first )
rule([[ InsertAuto <- '' ]], ' auto' )
rule([[ ConstantType <- 'val' ]], 'const' )
rule([[ VariableType <- 'var' ]], '' )
table.insert(keywords, "ConstSpecifier")

rule([[ AssignOperator <- ':=' ]], "=" )
rule([[ TypeDeclareOperator <- ':' ]], "=" )

table.insert(globalStatements, "SimpleDeclaration")
table.insert(localStatements, "SimpleDeclaration")
table.insert(localStatements, "Assignment")
