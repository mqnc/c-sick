FunctionDeclaration <- ~FunctionKeyword ~_ Identifier ~_ FunctionSpecifiers ~_ ParameterList ~_ ReturnValues ~_ ~break FunctionBody ~EndFunctionKeyword ~_ ~break
FunctionKeyword <- 'function'
FunctionSpecifiers: concat <- ('[' ~_ (Identifier ~_)* ']')?
ParameterList <- ('(' ~_ (ParameterDeclaration (~_ ',' ~_ ParameterDeclaration)*)? ~_ ')')?
ParameterDeclaration: concat <- (Identifier ~_)+ (ParameterAssignOperator ~_ Expression)? # specifiers included in the identifiers
ParameterAssignOperator <- AssignOperator
ReturnValues <- ('->' ~_ (ParameterDeclaration / ParameterList))?
FunctionBody <- skip (!EndFunctionKeyword LocalToken skip)*
EndFunctionKeyword <- 'end'



actions.FunctionDeclaration = function(params)

	local name = params.values[1].output
	local specifiers = params.values[2].output
	local parameters = params.values[3].output
	local returns = params.values[4].output
	local body = params.values[5].output

	output = specifiers .. name .. "(" .. parameters .. ")"

	output = output .. "{\n" .. body .. "\n}\n"

	return output
end

actions.ParameterList = function(params)
	local output = ""
	if #params.values >= 1 then
		output = params.values[1].output
	end
	for i = 2, #params.values do
		output = output .. ", " .. params.values[i].output
	end
	return output
end

actions.ParameterAssignOperator = function(params) return " = " end
