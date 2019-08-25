
print(col("TODO: SCAN FOR RETURN STATEMENTS INSIDE INNER SCOPES", "brightred"))

rule([[ FunctionDeclaration <- FunctionKeyword _ FunctionSpecifiers _ Identifier _ Parameters _ ReturnDeclaration _ Terminal FunctionBody EndFunctionKeyword ]],
	function(arg)
		local specs = arg.values[3]
		local name = arg.values[5]
		local params = arg.values[7]
		local retn = arg.values[9]
		local body = arg.values[12]

		----------------------
		-- check specifiers --
		----------------------
		local inline = false
		local kwargs = false
		if specs.subrule == "FunctionSpecifierList" then
			for i=1, #specs do
 				if specs[i].subrule == "FunctionInline" then
					inline = true
				elseif specs[i].subrule == "FunctionKwargs" then
					kwargs = true
				end
			end
		end

		------------------------
		-- scan for templates --
		------------------------
		local result = ""
		local template = "template<"
		local itparam = 0

		for i=1, #params do
			if params[i].decl.subrule == "TemplatedParameter" then
				if itparam>0 then template = template .. ", " end
				itparam = itparam+1
				template = template .. "typename T" .. itparam
			end
		end
		template = template .. ">\n"

		if itparam > 0 then result = result .. template end

		------------------------
		-- check return types --
		------------------------
		if inline then
			result = result .. "inline "
		end

		local arrowReturn = false
		if retn.subrule == "ExplicitReturnDeclaration" then
			-- we will use the -> notation
			result = result .. "auto "
			arrowReturn = true
		else
			-- we have to scan for the return statement
			local foundReturn
			for i=1, #body.values do
				if body.values[i].rule == "ReturnStatement" then
					foundReturn = true
					if body.values[i].type == "ReturnNothing" then
						result = result .. "void "
					else
						result = result .. "auto " -- return type deduction
					end
					break
				end
			end
			if not foundReturn then
				result = result .. "void "
			end
		end

		-------------------
		-- function name --
		-------------------
		result = result .. name[1]

		----------------
		-- parameters --
		----------------
		result = result .. "("
		itparam = 0 -- template parameter counter
		for i=1, #params do
			if i>1 then result = result .. ", " end

			if params[i].specs.subrule == "ConstantParameterSpecifier" then
				result = result .. "const "
			end

			if params[i].decl.subrule == "TemplatedParameter" then
				itparam = itparam+1
				result = result .. "T" .. itparam .. " " .. params[i].name[1]
			elseif params[i].decl.subrule == "RequiredParameter" then
				result = result .. params[i].decl[1] .. " " .. params[i].name[1]
			elseif params[i].decl.subrule == "DefaultParameter" then
				result = result .. "decltype(" .. params[i].decl[1] .. ") " .. params[i].name[1] .. " = " .. params[i].decl[1]
			end
		end
		result = result .. ")"

		------------------
		-- arrow return --
		------------------
		if arrowReturn then
			result = result .. " -> "

			if retn.fields.rule == "Type" then
				result = result .. retn.fields[1]

			elseif retn.fields.rule == "ReturnTuple" then
				result = result .. "std::tuple<"
				for i=1, #retn.fields do
					if i>1 then result = result .. ", " end
					result = result .. retn.fields[i].spec .. " " .. retn.fields[i].name
				end
				result = result .. ">"

			elseif retn.fields.rule == "ReturnStruct" then
				local structName = mark .. name[1] .. "_result"
				local struct = "struct " .. structName .. "{\n"
				for i=1, #retn.fields do
					struct = struct .. retn.fields[i].spec .. " " .. retn.fields[i].type .. " " .. retn.fields[i].name .. ";\n"
				end
				local tupleType = "std::tuple<"
				for i=1, #retn.fields do
					if i>1 then tupleType = tupleType .. ", " end
					tupleType = tupleType .. retn.fields[i].spec .. " " .. retn.fields[i].type
				end
				tupleType = tupleType .. ">"
				struct = struct .. structName .. "(" .. tupleType .. " " .. mark .. "tup):\n"
				for i=1, #retn.fields do
					struct = struct .. retn.fields[i].name .. "(std::get<" .. i-1 .. ">(" .. mark .. "tup))"
					if i<#retn.fields then struct = struct .. ",\n" end
				end
				struct = struct .. "{}\n"
				struct = struct .. "operator " .. tupleType .. "(){\nreturn {"
				for i=1, #retn.fields do
					if i>1 then struct = struct .. ", " end
					struct = struct .. retn.fields[i].name
				end
				struct = struct .. "};\n}\n};\n"

				result = struct .. result .. structName
			end
		end

		----------
		-- body --
		----------
		result = result .. "\n{\n"
		for i=1, #body.values do
			result = result .. body.values[i][1]
		end
		result = result .. "\n}\n"

		--dump({specs=specs, name=name, params=params, retn=retn, body=body})
		--dump(result)

		return {result}
	end
)
table.insert(globalStatements, "FunctionDeclaration")

-- return the first and then every fourth value (often needed for lists)
function listFilter(arg)
	resultTbl = {}
	for i=1, #arg.values, 4 do
		table.insert(resultTbl, arg.values[i])
	end
	return resultTbl
end

rule([[ FunctionKeyword <- 'function' ]])
table.insert(keywords, "FunctionKeyword")

rule([[ FunctionSpecifiers <- FunctionSpecifierList / NoFunctionSpecifiers ]], basic.first )
rule([[ NoFunctionSpecifiers <- "" ]])
rule([[ FunctionSpecifierList <- LBracket _ SpecifierList _ RBracket ]], basic.third )
rule([[ SpecifierList <- FunctionSpecifier (_ Comma _ FunctionSpecifier)* ]], listFilter)
rule([[ FunctionSpecifier <- FunctionInline / FunctionKwargs ]], basic.first)
rule([[ FunctionInline <- "inline" ]])
rule([[ FunctionKwargs <- "kwargs" ]])
table.insert(keywords, "FunctionInline")
table.insert(keywords, "FunctionKwargs")

rule([[ Parameters <- ParameterList / NoParameters ]], basic.first )
rule([[ NoParameters <- (LParen _ RParen)? ]], function(arg) return {} end)
rule([[ ParameterList <- LParen _ ParameterDeclarationList _ RParen ]], basic.third )

rule([[ ParameterDeclaration <- ParameterSpecifier _ Identifier _ ParameterTypeDeclaration ]], function(arg)
	return {specs = arg.values[1], name = arg.values[3], decl = arg.values[5]} end )

rule([[ ParameterTypeDeclaration <- DefaultParameter / RequiredParameter / TemplatedParameter ]], basic.first )
rule([[ DefaultParameter <- AssignOperator _ Expression ]], basic.third )
rule([[ RequiredParameter <- TypeDeclareOperator _ Identifier ]], basic.third )
rule([[ TemplatedParameter <- '' ]])

rule([[ ParameterDeclarationList <- ParameterDeclaration (_ Comma _ ParameterDeclaration)* ]], listFilter)

rule([[ ParameterSpecifier <- VariableParameterSpecifier / ConstantParameterSpecifier  ]], basic.first )
rule([[ ConstantParameterSpecifier <- '' ]], 'const' )
rule([[ VariableParameterSpecifier <- 'var' ]], '' )

rule([[ ReturnDeclaration <- ExplicitReturnDeclaration / AutoReturnType ]], basic.first )
rule([[ AutoReturnType <- '' ]])
rule([[ ExplicitReturnDeclaration <- ReturnOperator _ ReturnType ]], basic.third )
rule([[ ReturnOperator <- '->' ]])

rule([[ ReturnType <- ReturnTuple / ReturnStruct / Type]],
 	function(arg) return{fields=arg.values[1]} end )

-- tuple when two or more return values
rule([[ ReturnTuple <- SpecifiedType _ Comma _  SpecifiedType (_ Comma _  SpecifiedType)* ]], listFilter )
rule([[ SpecifiedType <- ParameterSpecifier _ Type ]], function(arg) return {spec=arg.values[1][1], name=arg.values[3][1]} end )

rule([[ ReturnStruct <- ReturnStructField _ Comma _ ReturnStructField (_ Comma _  ReturnStructField)* ]], listFilter )

rule([[ ReturnStructField <- ParameterSpecifier _ Identifier _ TypeDeclareOperator _ Type ]],
	function(arg) return {spec=arg.values[1][1], name=arg.values[3][1], type=arg.values[7][1]} end )

rule([[ FunctionBody <- Skip (!EndFunctionKeyword (ReturnStatement / LocalStatement) Skip)* ]], basic.tree )

rule([[ ReturnStatement <- ReturnKeyword _ Returnee _ Terminal ]], function(arg)
	local v = arg.values
	return {[1] = v[1][1] .. v[2][1] .. v[3][1] .. v[4][1] .. v[5][1], type = v[3].rule}
end )

rule([[ Returnee <- Assigned / ReturnNothing ]], basic.first )

rule([[ ReturnNothing <- '' ]], '')

rule([[ ReturnKeyword <- 'return' ]], 'return')

rule([[ EndFunctionKeyword <- 'end' ]])
table.insert(keywords, "EndFunctionKeyword")
