
print(col("TODO: SCAN FOR RETURN STATEMENTS INSIDE INNER SCOPES", "brightred"))
print(col("TODO: KWARGS", "brightred"))

rule([[ FunctionDeclaration <- FunctionKeyword _ FunctionSpecifiers _ Identifier _ Parameters _ ReturnDeclaration _ Terminal FunctionBody EndFunctionKeyword ]],
	function(sv, info)
		local specs = sv[3]
		local name = sv[5]
		local params = sv[7]
		local retn = sv[9]
		local body = sv[12]
		local lastretn = sv[13]

		--dump({specs=specs, name=name, params=params, retn=retn, body=body, lastretn=lastretn})
		dump(retn)

		local result = ""

		----------------------
		-- check specifiers --
		----------------------
		local inline = false
		local kwargs = false
		if specs.choice == "list" then
			for i=1, #specs do
 				if specs[i].txt == "inline" then
					inline = true
				elseif specs[i].txt == "kwargs" then
					kwargs = true
				end
			end
		end

		------------------------
		-- scan for templates --
		------------------------

		local itparam = 0
		local templates = {}
		for i=1, #params do
			if params[i].decl.choice == "templated" then
				itparam = itparam+1
				table.insert(templates, "typename T" .. itparam)
			end
		end
		if #templates > 0 then
			result = result .. "template<" ..table.concat(templates, ", ") .. ">\n"
		end

		------------------------
		-- check return types --
		------------------------
		if inline then
			result = result .. "inline "
		end

		local arrowReturn = false
		if retn.choice == "explicit" then
			-- we will use the -> notation
			result = result .. "auto "
			arrowReturn = true
		else
			if lastretn.retn.choice == nil or lastretn.retn.choice == "void" then
				result = result .. "void "
			else
				result = result .. "auto " -- return type deduction
			end
		end

		-------------------
		-- function name --
		-------------------
		result = result .. name.txt

		----------------
		-- parameters --
		----------------
		result = result .. "("
		itparam = 0 -- template parameter counter
		for i=1, #params do
			if i>1 then result = result .. ", " end

			if params[i].specs.choice == "constant" then
				result = result .. "const "
			end

			if params[i].decl.choice == "templated" then
				itparam = itparam+1
				result = result .. "T" .. itparam .. " " .. params[i].name.txt
			elseif params[i].decl.choice == "required" then
				result = result .. params[i].decl.txt .. " " .. params[i].name.txt
			elseif params[i].decl.choice == "default" then
				result = result .. "decltype(" .. params[i].decl.txt .. ") " .. params[i].name.txt .. " = " .. params[i].decl.txt
			end
		end
		result = result .. ")"

		------------------
		-- arrow return --
		------------------
		if arrowReturn then
			result = result .. " -> "

			if retn.subchoice == "single" then
				result = result .. retn.txt

			elseif retn.subchoice == "tuple" then
				result = result .. "std::tuple<"
				local retnfields = {}
				for i=1, #retn do
					table.insert(retnfields, retn[i].spec .. " " .. retn[i].name)
				end
				result = result .. table.concat(retnfields, ", ") .. ">"

			elseif retn.subchoice == "struct" then

				-- struct NAME{
				local structName = mark .. name.txt .. "_result"
				local struct = "struct " .. structName .. "{\n"

				-- list members
				local fields = {}
				for i=1, #retn do
					table.insert(fields, retn[i].spec .. " " .. retn[i].type .. " " .. retn[i].name .. ";\n")
				end
				struct = struct .. table.concat(fields)

				-- construct tuple to construct from / cast to
				local typelist = {}
				for i=1, #retn do
					table.insert(typelist, retn[i].spec .. " " .. retn[i].type)
				end
				local tupleType = "std::tuple<" .. table.concat(typelist) .. ">"

				-- constructor from tuple
				struct = struct .. structName .. "(" .. tupleType .. " " .. mark .. "tup):\n"
				local coloninits = {}
				for i=1, #retn do
					table.insert(coloninits, retn[i].name .. "(std::get<" .. i-1 .. ">(" .. mark .. "tup))")
				end
				struct = struct .. table.concat(coloninits, ",\n") .. "{}\n"

				-- cast to tuple operator
				struct = struct .. "operator " .. tupleType .. "(){\nreturn {"
				local bracelist = {}
				for i=1, #retn do
					table.insert(bracelist, retn[i].name)
				end
				struct = struct .. table.concat(bracelist) .. "};\n}\n};\n"

				result = struct .. result .. structName
			end
		end

		----------
		-- body --
		----------
		result = result .. "\n{\n" .. body.txt .. "\n}\n"

		dump(result)
		return {txt=result}
	end
)
table.insert(globalStatements, "FunctionDeclaration")

-- return the first and then every fourth value (often needed for lists)
function listFilter(sv, info)
	resultTbl = {}
	for i=1, #sv, 4 do
		table.insert(resultTbl, sv[i])
	end
	return resultTbl
end

rule([[ FunctionKeyword <- 'function' ]], function()
	-- push an empty slot to the function stack for the return statement to store its info in
	table.insert(functionStack, {})
	return {}
end )
table.insert(keywords, "FunctionKeyword")

rule([[ FunctionSpecifiers <- FunctionSpecifierList / NoFunctionSpecifiers ]], basic.choice("list", "none") )
rule([[ NoFunctionSpecifiers <- "" ]])
rule([[ FunctionSpecifierList <- LBracket _ SpecifierList _ RBracket ]], basic.forward(3) )
rule([[ SpecifierList <- FunctionSpecifier (_ Comma _ FunctionSpecifier)* ]], listFilter)
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

rule([[ ParameterDeclarationList <- ParameterDeclaration (_ Comma _ ParameterDeclaration)* ]], listFilter)

rule([[ ParameterSpecifier <- VariableParameterSpecifier / ConstantParameterSpecifier  ]], basic.choice("variable", "constant") )
rule([[ ConstantParameterSpecifier <- '' ]], 'const' )
rule([[ VariableParameterSpecifier <- 'var' ]], '' )

rule([[ ReturnDeclaration <- ExplicitReturnDeclaration / DeduceReturnType ]], basic.choice("explicit", "deduce") )
rule([[ DeduceReturnType <- '' ]])
rule([[ ExplicitReturnDeclaration <- ReturnOperator _ ReturnType ]], basic.forward(3) )
rule([[ ReturnOperator <- '->' ]])

rule([[ ReturnType <- ReturnTuple / ReturnStruct / Type]], basic.subchoice("tuple", "struct", "single") )

-- tuple when two or more return values
rule([[ ReturnTuple <- SpecifiedType _ Comma _ SpecifiedType (_ Comma _ SpecifiedType)* ]], listFilter )
rule([[ SpecifiedType <- ParameterSpecifier _ Type ]], function(sv, info) return {spec=sv[1].txt, name=sv[3].txt} end )

rule([[ ReturnStruct <- ReturnStructField _ Comma _ ReturnStructField (_ Comma _  ReturnStructField)* ]], listFilter )

rule([[ ReturnStructField <- ParameterSpecifier _ Identifier _ TypeDeclareOperator _ Type ]],
	function(sv, info) return {spec=sv[1].txt, name=sv[3].txt, type=sv[7].txt} end )

rule([[ FunctionBody <- Skip (!EndFunctionKeyword (ReturnStatement / LocalStatement) Skip)* ]], basic.concat )

--rule([[ ReturnStatement <- ReturnKeyword _ Returnee _ Terminal ]], function(sv, info)
--	return {[1] = sv[1].txt .. sv[2].txt .. sv[3].txt .. sv[4].txt .. sv[5].txt, type = sv[3].rule}
--end )
rule([[ ReturnStatement <- ReturnKeyword _ Returnee _ Terminal ]], function(sv, info)
	-- store the returnee in the function stack so the function can access it
	functionStack[#functionStack] = sv[3]
	return basic.concat(sv, info)
end )

rule([[ Returnee <- Assigned / ReturnNothing ]], basic.choice("nonvoid", "void") )

rule([[ ReturnNothing <- '' ]], '')

rule([[ ReturnKeyword <- 'return' ]], 'return')

rule([[ EndFunctionKeyword <- 'end' ]], function()
	-- pop the stored return value from the function stack and return it
	return {retn = table.remove(functionStack)}
end )
table.insert(keywords, "EndFunctionKeyword")
