IfStatement: concat <- IfPart (ElseIfPart)* ElsePart? ~EndIfKeyword ~_ ~break
IfPart <- ~IfKeyword ~_ Condition ~_ ~break IfBody
IfKeyword: ~ <- 'if'
Condition: subs <- Expression
IfBody: subs <- skip (!ElseIfKeyword !ElseKeyword !EndIfKeyword LocalToken skip)*
ElseIfPart <- ~ElseIfKeyword ~_ Condition ~_ ~break IfBody
ElseIfKeyword: ~ <- 'elseif'
ElsePart <- ~ElseKeyword ~_ ~break IfBody
ElseKeyword: ~ <- 'else'
EndIfKeyword: ~ <- 'end'

SwitchStatement <- ~SwitchKeyword ~_ Condition ~_ ~break ~skip (Case ~skip)* ~EndSwitchKeyword
SwitchKeyword: ~ <- 'switch'
Case <- (CaseCondition / DefaultKeyword) ~break OptionalCaseBody (FallKeyword ~_ ~break)? ~skip
CaseCondition <- ~CaseKeyword ~_ (Expression / DefaultKeyword) ~_ (',' ~_ (Expression / DefaultKeyword) ~_)*
CaseKeyword: ~ <- 'case'
OptionalCaseBody: subs <- skip (!FallKeyword !CaseKeyword !DefaultKeyword !EndSwitchKeyword LocalToken skip)*
FallKeyword: ~ <- 'fall'
DefaultKeyword: ~ <- 'default'
EndSwitchKeyword: ~ <- 'end'


actions.IfPart = function(params)
	return "if( " .. params.values[1].output .. " ){\n" .. params.values[2].output .. "\n}\n"
end

actions.ElseIfPart = function(params)
	return "else if( " .. params.values[1].output .. " ){\n" .. params.values[2].output .. "\n}\n"
end

actions.ElsePart = function(params)
	return "else{\n" .. params.values[1].output .. "\n}\n"
end



actions.SwitchStatement = function(params)
	local output = "switch(" .. params.values[1].output .. "){\n"
	for i = 2, #params.values do
		output = output .. params.values[i].output
	end
	output = output .. "\n}\n"
	return output
end

actions.CaseCondition = function(params)
	local i = 1
	local output = ""
	for i, val in ipairs(params.values) do
		if val.rule == "DefaultKeyword" then
			output = output .. val.output
		else
			output = output .. "case(" .. val.output .. "): "
		end
	end
	return output
end

actions.Case = function(params)
	local output = params.values[1].output .. "\n" .. params.values[2].output .. "\n"
	if #params.values == 2 then -- no fall keyword
		output = output .. "break;\n"
	end
	return output
end

actions.DefaultKeyword = function(params)
	return "default: "
end
