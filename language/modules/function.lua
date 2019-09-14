
rule([[ FunctionDeclaration <- FunctionKeyword _ FunctionSpecifiers _ Identifier _ Parameters _ ReturnDeclaration _ Terminal FunctionBody EndFunctionKeyword ]], functionGenerator )

table.insert(globalStatements, "FunctionDeclaration")

rule([[ FunctionKeyword <- 'function' ]], function()
	-- push an empty slot to the function stack for the return statement to store its info in
	table.insert(functionStack, {})
	return {}
end )
table.insert(keywords, "FunctionKeyword")

rule([[ FunctionSpecifiers <- FunctionSpecifierList / NoFunctionSpecifiers ]], basic.choice("list", "none") )
rule([[ NoFunctionSpecifiers <- "" ]])
rule([[ FunctionSpecifierList <- LBracket _ SpecifierList _ RBracket ]], basic.forward(3) )
rule([[ SpecifierList <- FunctionSpecifier (_ Comma _ FunctionSpecifier)* ]], basic.listFilter)
rule([[ FunctionSpecifier <- FunctionInline / FunctionKwargs ]], basic.match )
rule([[ FunctionInline <- "inline" ]])
rule([[ FunctionKwargs <- "kwargs" ]])
table.insert(keywords, "FunctionInline")
table.insert(keywords, "FunctionKwargs")

rule([[ Parameters <- ParameterList / NoParameters ]], basic.forward(1) )
rule([[ NoParameters <- (LParen _ RParen)? ]], function(sv, info) return {} end)
rule([[ ParameterList <- LParen _ ParameterDeclarationList _ RParen ]], basic.forward(3) )

rule([[ ParameterDeclaration <- ParameterSpecifier _ Identifier _ ParameterTypeDeclaration ]], function(sv, info)
	return {specs = sv[1], name = sv[3], decl = sv[5]} end )

rule([[ ParameterTypeDeclaration <- DefaultParameter / RequiredParameter / TemplatedParameter ]], basic.choice("default", "required", "templated") )
rule([[ DefaultParameter <- AssignOperator _ Expression ]], basic.forward(3) )
rule([[ RequiredParameter <- TypeDeclareOperator _ Identifier ]], basic.forward(3) )
rule([[ TemplatedParameter <- '' ]])

rule([[ ParameterDeclarationList <- ParameterDeclaration (_ Comma _ ParameterDeclaration)* ]], basic.listFilter)

rule([[ ParameterSpecifier <- VariableParameterSpecifier / ConstantParameterSpecifier  ]], basic.choice("variable", "constant") )
rule([[ ConstantParameterSpecifier <- '' ]], 'const' )
rule([[ VariableParameterSpecifier <- 'var' ]], '' )

rule([[ ReturnDeclaration <- ExplicitReturnDeclaration / DeduceReturnType ]], basic.choice("explicit", "deduce") )
rule([[ DeduceReturnType <- '' ]])
rule([[ ExplicitReturnDeclaration <- ReturnOperator _ ReturnType ]], basic.forward(3) )
rule([[ ReturnOperator <- '->' ]])

rule([[ ReturnType <- ReturnTuple / ReturnStruct / Type]], basic.subchoice("tuple", "struct", "single") )

-- tuple when two or more return values
rule([[ ReturnTuple <- SpecifiedType _ Comma _ SpecifiedType (_ Comma _ SpecifiedType)* ]], basic.listFilter )
rule([[ SpecifiedType <- ParameterSpecifier _ Type ]], function(sv, info) return {spec=sv[1].txt, name=sv[3].txt} end )

rule([[ ReturnStruct <- ReturnStructField _ Comma _ ReturnStructField (_ Comma _  ReturnStructField)* ]], basic.listFilter )

rule([[ ReturnStructField <- ParameterSpecifier _ Identifier _ TypeDeclareOperator _ Type ]],
	function(sv, info) return {spec=sv[1].txt, name=sv[3].txt, type=sv[7].txt} end )

rule([[ FunctionBody <- Skip (!EndFunctionKeyword LocalStatement Skip)* ]], basic.concat )

--rule([[ ReturnStatement <- ReturnKeyword _ Returnee _ Terminal ]], function(sv, info)
--	return {[1] = sv[1].txt .. sv[2].txt .. sv[3].txt .. sv[4].txt .. sv[5].txt, type = sv[3].rule}
--end )
rule([[ ReturnStatement <- ReturnKeyword _ Returnee _ Terminal ]], function(sv, info)
	-- store the returnee in the function stack so the function can access it
	functionStack[#functionStack] = sv[3]
	return basic.concat(sv, info)
end )
table.insert(localStatements, "ReturnStatement")

rule([[ Returnee <- Assigned / ReturnNothing ]], basic.choice("nonvoid", "void") )

rule([[ ReturnNothing <- '' ]], '')

rule([[ ReturnKeyword <- 'return' ]], 'return')

rule([[ EndFunctionKeyword <- 'end' ]], function()
	-- pop the stored return value from the function stack and return it
	return {retn = table.remove(functionStack)}
end )
table.insert(keywords, "EndFunctionKeyword")
