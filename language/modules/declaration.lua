
rule([[ SimpleDeclaration <- ConstSpecifier InsertAuto _ SimpleDeclaree _ AssignOperator _ Assigned _ Terminal ]], basic.concat )
rule([[ SimpleDeclaree <- StructuredBinding / Identifier ]], basic.concat )
rule([[ StructuredBinding <- InsertLBracket _ IdentifierListMulti _ InsertRBracket ]], basic.concat )

rule([[ Assignment <- TieToValues / AssignToValue ]], basic.concat )

rule([[ AssignToValue <- Expression _ AssignOperator _ Assigned _ Terminal ]], basic.concat )

rule([[ TieToValues <- IdentifierListMulti _ AssignOperator _ Assigned _ Terminal ]], function(sv, info)
	return {txt ="std::tie(" .. sv[1].txt .. ") " .. sv[2].txt .. " = " ..
			sv[4].txt .. "static_cast<std::tuple<decltype(" .. table.concat(sv[1].idents, "), decltype(") ..
 			")>>(" .. sv[5].txt .. ")" .. sv[6].txt .. sv[7].txt}
end )

rule([[ Assigned <- AssignedTuple / Expression ]], basic.concat )
rule([[ AssignedTuple <- ExpressionListMulti ]], 'std::make_tuple({1})' )

rule([[ SimpleDeclarationList <- SimpleDeclaration (_ Comma _ SimpleDeclaration)* ]], basic.concat )

rule([[ ConstSpecifier <- ConstantType / VariableType ]], basic.forward(1) )
rule([[ InsertAuto <- '' ]], ' auto' )
rule([[ ConstantType <- 'const' ]], 'const' )
rule([[ VariableType <- 'var' ]], '' )
table.insert(keywords, "ConstSpecifier")

rule([[ AssignOperator <- ':=' ]], "=" )
rule([[ TypeDeclareOperator <- ':' ]], "=" )

table.insert(globalStatements, "SimpleDeclaration")
table.insert(localStatements, "SimpleDeclaration")
table.insert(localStatements, "Assignment")
