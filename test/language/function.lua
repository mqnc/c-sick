

rule([[ FunctionDeclaration <- FunctionKeyword _ {Identifier} _ {FunctionSpecifiers} _ {ParameterList} _ {ReturnValues} _ break
	{FunctionBody} EndFunctionKeyword _ break ]],
	function(params)

		local name = params.values[1].output
		local specifiers = params.values[2].output
		local parameters = params.values[3].output
		local returns = params.values[4].output.values
		local body = params.values[5].output

		local output = ""

		if #returns == 0 then
			output = specifiers .. " " .. name .. "(" .. parameters .. ")"
		elseif returns[1].rule == "ReturnType"
			output = specifiers .. " " .. returns[1].output .. " " .. name .. "(" .. parameters .. ")"
		elseif returns[1].rule == "DeclarationWithInit"
			output = specifiers .. " " .. returns[1].output .. " " .. name .. "(" .. parameters .. ")"
		end


		output = output .. "{\n" .. body .. "\n}\n"

		return output
	end
)
rule([[ FunctionKeyword <- 'function' ]])
table.insert(keywords, "FunctionKeyword")
rule([[ FunctionSpecifiers <- ('[' _ ({Identifier} _)* ']')? ]], basic.concat )
rule([[ ParameterList <- ('(' _ (SimpleDeclaration (_ ',' _ SimpleDeclaration)*)? _ ')')? ]], basic.csv )
rule([[ ReturnValues <- ('->' _ ({DeclarationWithInit} / {ParameterList} / {ReturnType}))? ]], basic.forward )
rule([[ ReturnType <- {Identifier}+ ]], basic.concat )
rule([[ FunctionBody <- {skip} (!EndFunctionKeyword {LocalStatement} {skip})* ]], basic.subs )
rule([[ EndFunctionKeyword <- 'end' ]])
table.insert(keywords, "EndFunctionKeyword")
