

rule([[ FunctionDeclaration <- FunctionKeyword _ {Identifier} _ {FunctionSpecifiers} _ {ParameterList} _ {ReturnValues} _ break
	{FunctionBody} EndFunctionKeyword _ break ]],
	function(arg)
		local result = sv(arg)

		local name = arg.values[1]
		local specifiers = arg.values[2]
		local parameters = arg.values[3]
		local returns = arg.values[4]
		local body = arg.values[5]

		local sep = ""
		local paramstr = ""
		for i, par in ipairs(parameters.values) do
			paramstr = paramstr .. sep .. par.str
			sep = ", "
		end

		if #returns.values == 0 then
			result.str =
				specifiers.str .. " void " .. name.str .. "(" .. paramstr .. ")" ..
				"{\n" .. body.str .. "\n}\n"

		elseif returns.values[1].rule == "ReturnType" then
			result.str =
				specifiers.str .. " " .. returns.values[1].str .. " " .. name.str .. "(" .. paramstr .. ")" ..
				"{\n" .. body.str .. "\n}\n"

		elseif returns.values[1].rule == "DeclarationWithInit" then
			result.str =
				specifiers.str .. " " .. table.concat(returns.values[1].specifiers, " ") .. " " ..
				name.str .. "(" .. paramstr .. ")" ..
				"{\n" .. returns.values[1].str .. ";\n" ..
				body.str .. "\n" ..
				"return " .. returns.values[1].variable .. ";\n}\n"

		else -- parameter list -> we want to return a struct
			local decls = returns.values[1].values
			result.str = "struct " .. name.str .. "__result{\n"
			local allInitialized = true
			for i, decl in ipairs(decls) do
				for j, spec in ipairs(decl.specifiers) do
					result.str = result.str .. spec .. " "
				end
				result.str = result.str .. decl.variable .. ";\n"
				if decl.init == nil then
					allInitialized = false
				end
			end
			result.str = result.str .. "}\n" .. specifiers.str .. name.str .. "__result " .. "(" .. paramstr .. ")\n{\n"
			if allInitialized then
				for i, decl in ipairs(decls) do
					result.str = result.str .. decl.str .. ";\n"
				end
				result.str = result.str .. body.str .. "\nreturn {"
				local sep = ""
				for i, ret in ipairs(decls) do
					result.str = result.str .. sep .. ret.variable
					sep = ", "
				end
				result.str = result.str .. "};\n}\n"
			else
				for i, decl in ipairs(decls) do
					if decl.init ~= nil then
						result.str = result.str .. decl.str .. ";\n"
					end
				end
				result.str = result.str .. body.str .. "\n}\n"
			end
		end

		return result
	end
)
table.insert(globalStatements, "{FunctionDeclaration}")

rule([[ FunctionKeyword <- 'function' ]])
table.insert(keywords, "FunctionKeyword")
rule([[ FunctionSpecifiers <- ('[' _ ({Identifier} _)* ']')? ]], basic.concat )
rule([[ ParameterList <- ('(' _ ({SimpleDeclaration} (_ ',' _ {SimpleDeclaration})*)? _ ')')? ]], basic.forward )
rule([[ ReturnValues <- ('->' _ ({DeclarationWithInit} / {ReturnType} / {ParameterList}))? ]], basic.forward )
rule([[ ReturnType <- ({Identifier} _)+ ]], basic.concat )
rule([[ FunctionBody <- {skip} (!EndFunctionKeyword ({ReturnStatement} / {LocalStatement}) {skip})* ]], basic.subs )
rule([[ ReturnStatement <- ReturnKeyword _ {Identifier} (_ ',' _ {Identifier})* _ break ]],
	function(arg)
		local result = sv(arg)
		local buf = ss()
		for i, val in ipairs(arg.values) do
			append(buf, val.str)
		end
		result.str = "return {" .. join(buf, ", ") .. "};\n"
		return result
	end
)
rule([[ ReturnKeyword <- 'return' ]])
table.insert(keywords, "ReturnKeyword")
rule([[ EndFunctionKeyword <- 'end' ]])
table.insert(keywords, "EndFunctionKeyword")
