--[[
This module provides functions. See function.mon for further details.
]]

rule([[ FunctionDeclaration <- ~FunctionKeyword ~_ Identifier ~_ FunctionSpecifiers ~_ ParameterList ~_ ReturnValues _ SilentTerminal
	FunctionBody ~EndFunctionKeyword ]],
	function(arg)
		local result = ""

		local name = arg.values[1]
		local specifiers = arg.values[2]
		local parameters = arg.values[3]
		local returns = arg.values[4]
		local comment = arg.values[5][1] .. arg.values[6][1]
		local body = arg.values[7]

		local buf = {}
		for i=2, #parameters.values, 3 do
			-- declaration and comments
			buf[#buf+1] = parameters.values[i-1][1] .. " " .. parameters.values[i][1] .. " " .. parameters.values[i+1][1]
		end
		local paramstr = table.concat(buf, ", ")

		if #returns.values == 0 then
			result =
				specifiers[1] .. " void " .. name[1] .. "(" .. paramstr .. ")" .. comment ..
				"{\n" .. body[1] .. "\n}\n"

		elseif returns.values[1].rule == "ReturnType" then
			result =
				specifiers[1] .. " " .. returns.values[1][1] .. " " .. name[1] .. "(" .. paramstr .. ")" .. comment ..
				"{\n" .. body[1] .. "\n}\n"

		elseif returns.values[1].rule == "DeclarationWithInit" then
			result =
				specifiers[1] .. " " .. table.concat(returns.values[1].specifiers, " ") .. " " ..
				name[1] .. "(" .. paramstr .. ")" .. comment ..
				"{\n" .. returns.values[1][1] .. ";\n" ..
				body[1] .. "\n" ..
				"return " .. returns.values[1].variable .. ";\n}\n"

		else -- parameter list -> we want to return a struct
			local decls = {}
			for i=2, #returns.values[1].values, 3 do -- comment, declaration, comment
				decls[#decls+1] = returns.values[1].values[i]
				decls[#decls].preComment = returns.values[1].values[i-1][1]
				decls[#decls].postComment = returns.values[1].values[i+1][1]
			end

			result = "struct " .. name[1] .. "__result{\n"
			local allInitialized = true
			for i, decl in ipairs(decls) do
				result = result .. decl.preComment .. " "
				for j, spec in ipairs(decl.specifiers) do
					result = result .. spec .. " "
				end
				result = result .. decl.variable .. "; " .. decl.postComment .. "\n"
				if decl.init == nil then
					allInitialized = false
				end
			end
			result = result .. "}\n" .. specifiers[1] .. name[1] .. "__result " .. name[1] .. "(" .. paramstr .. ") " .. comment .. "\n{\n"
			if allInitialized then
				for i, decl in ipairs(decls) do
					result = result .. decl[1] .. ";\n"
				end
				result = result .. body[1] .. "\nreturn {"
				local sep = ""
				for i, ret in ipairs(decls) do
					result = result .. sep .. ret.variable
					sep = ", "
				end
				result = result .. "};\n}\n"
			else
				for i, decl in ipairs(decls) do
					if decl.init ~= nil then
						result = result .. decl[1] .. ";\n"
					end
				end
				result = result .. body[1] .. "\n}\n"
			end
		end

		return {result}
	end
)
table.insert(globalStatements, "FunctionDeclaration")

rule([[ FunctionKeyword <- 'function' ]])
table.insert(keywords, "FunctionKeyword")
rule([[ FunctionSpecifiers <- ('[' _ (Identifier _)* ']')? ]], basic.concat )
rule([[ ParameterList <- ('(' _ (SimpleDeclaration _ (',' _ SimpleDeclaration _)*)? ')')? ]], basic.tree )
rule([[ ReturnValues <- ('->' ~_ (DeclarationWithInit / ReturnType / ParameterList))? ]], basic.tree )
rule([[ ReturnType <- (Identifier _)+ ]], basic.concat )
rule([[ FunctionBody <- Skip (!EndFunctionKeyword (ReturnStatement / LocalStatement) Skip)* ]], basic.concat )
rule([[ ReturnStatement <- ~ReturnKeyword ~_ Identifier (~_ ',' ~_ Identifier)* _ SilentTerminal ]],
	function(arg)
		local buf = {}
		for i, val in ipairs(arg.values) do
			buf[#buf+1] = val[1]
		end
		local comment2 = buf[#buf]
		buf[#buf] = nil
		local comment1 = buf[#buf]
		buf[#buf] = nil

		return {"return {" .. table.concat(buf, ", ") .. "}; " .. comment1 .. comment2}
	end
)
rule([[ ReturnKeyword <- 'return' ]])
table.insert(keywords, "ReturnKeyword")
rule([[ EndFunctionKeyword <- 'end' ]])
table.insert(keywords, "EndFunctionKeyword")
