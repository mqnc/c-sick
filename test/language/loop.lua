
rule([[ WhileStatement <- WhileKeyword _ {Expression} _ break {WhileBody} EndWhileKeyword ]],
	function(params)
		return "while( " .. params.values[1].output .. " ){\n" .. params.values[2].output .. "\n}\n"
	end
)
rule([[ WhileKeyword <- 'while' ]])
table.insert(keywords, "WhileKeyword")
rule([[ WhileBody <- {skip} (!EndWhileKeyword {LocalStatement} {skip})* ]], basic.subs )
rule([[ EndWhileKeyword <- 'end' ]])
table.insert(keywords, "EndWhileKeyword")

table.insert(localStatements, "{WhileStatement}")


rule([[ RepeatStatement <- RepeatKeyword _ break {RepeatBody} ({RepWhileKeyword} / {UntilKeyword}) _ {Expression} _ break ]],
	function(params)
		local condition = ""
		if params.values[2].rule == "RepWhileKeyword" then
			condition = "( " .. params.values[3].output .. " )"
		else
			condition = "(!( " .. params.values[3].output .. " ))"
		end
		return "do{\n" .. params.values[1].output .. "\n}\nwhile" .. condition .. "\n"
	end
)
rule([[ RepeatKeyword <- 'repeat' ]])
table.insert(keywords, "RepeatKeyword")
rule([[ RepeatBody <- {skip} (!RepWhileKeyword !UntilKeyword {LocalStatement} {skip})* ]], basic.subs )
rule([[ RepWhileKeyword <- 'whilst' ]])
table.insert(keywords, "RepWhileKeyword")
rule([[ UntilKeyword <- 'until' ]])
table.insert(keywords, "UntilKeyword")

table.insert(localStatements, "{RepeatStatement}")
