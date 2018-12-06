WhileStatement <- ~WhileKeyword ~_ Condition ~_ ~break WhileBody ~EndWhileKeyword
WhileKeyword: ~ <- 'while'
WhileBody: subs <- skip (!EndWhileKeyword LocalToken skip)*
EndWhileKeyword: ~ <- 'end'

RepeatStatement <- ~RepeatKeyword ~_ ~break RepeatBody (RepWhileKeyword / UntilKeyword) ~_ Condition ~_ ~break
RepeatKeyword <- 'repeat'
RepeatBody <- skip (!RepWhileKeyword !UntilKeyword LocalToken skip)*
RepWhileKeyword <- 'whilst'
UntilKeyword <- 'until'



actions.WhileStatement = function(params)
	return "while( " .. params.values[1].output .. " ){\n" .. params.values[2].output .. "\n}\n"
end



actions.RepeatStatement = function(params)
	local condition = ""
	if params.values[2].rule == "RepWhileKeyword" then
		condition = "( " .. params.values[3].output .. " )"
	else
		condition = "(!( " .. params.values[3].output .. " ))"
	end
	return "do{\n" .. params.values[1].output .. "\n}\nwhile" .. condition .. "\n"
end
