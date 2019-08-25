
rule([[ SimpleDeclaration <- ConstSpecifier InsertAuto _ SimpleDeclaree _ AssignOperator _ Assigned _ Terminal ]], basic.concat )
rule([[ SimpleDeclaree <- StructuredBinding / Identifier ]], basic.concat )
rule([[ StructuredBinding <- StructBindOpen _ IdentifierListMulti _ StructBindClose ]], basic.concat )
rule([[ StructBindOpen <- '' ]], '[')
rule([[ StructBindClose <- '' ]], ']')

rule([[ Assignment <- TieToValues / AssignToValue ]], basic.concat )

rule([[ AssignToValue <- Identifier _ AssignOperator _ Assigned _ Terminal ]], basic.concat )

rule([[ TieToValues <- IdentifierListMulti _ AssignOperator _ Assigned _ Terminal ]], function(arg)
	res = "std::tie(" .. arg.values[1][1] .. ") " .. arg.values[2][1] .. " = " .. arg.values[4][1] .. "static_cast<std::tuple<"
	for i = 1, #arg.values[1].idents do
		if i>1 then res = res .. ", " end
		res = res .. "decltype(" .. arg.values[1].idents[i] .. ")"
	end
	res = res .. ">>(" .. arg.values[5][1] .. ")" .. arg.values[6][1] .. arg.values[7][1]
	return {res}
end )

rule([[ Assigned <- AssignedTuple / Expression ]], basic.concat )
rule([[ AssignedTuple <- ExpressionListMulti ]], 'std::make_tuple({1})' )

rule([[ SimpleDeclarationList <- SimpleDeclaration (_ Comma _ SimpleDeclaration)* ]], basic.concat )

rule([[ ConstSpecifier <- ConstantType / VariableType ]], basic.first )
rule([[ InsertAuto <- '' ]], ' auto' )
rule([[ ConstantType <- 'const' ]], 'const' )
rule([[ VariableType <- 'var' ]], '' )
table.insert(keywords, "ConstSpecifier")

rule([[ AssignOperator <- ':=' ]], "=" )
rule([[ TypeDeclareOperator <- ':' ]], "=" )

table.insert(globalStatements, "SimpleDeclaration")
table.insert(localStatements, "SimpleDeclaration")
table.insert(localStatements, "Assignment")
