
rule([[ WhileStatement <- WhileKeyword _ {Expression} _ break {WhileBody} EndWhileKeyword ]],
	function(arg)
		local result = sv(arg)
		result.str = "while( " .. arg.values[1].str .. " ){\n" .. arg.values[2].str .. "\n}\n"
		return result
	end
)
rule([[ WhileKeyword <- 'while' ]])
table.insert(keywords, "WhileKeyword")
rule([[ WhileBody <- {skip} (!EndWhileKeyword {LocalStatement} {skip})* ]], basic.subs )
rule([[ EndWhileKeyword <- 'end' ]])
table.insert(keywords, "EndWhileKeyword")

table.insert(localStatements, "{WhileStatement}")


rule([[ RepeatStatement <- RepeatKeyword _ break {RepeatBody} ({RepWhileKeyword} / {UntilKeyword}) _ {Expression} _ break ]],
	function(arg)
		local result = sv(arg)
		local condition = ""
		if arg.values[2].rule == "RepWhileKeyword" then
			condition = "( " .. arg.values[3].str .. " )"
		else
			condition = "(!( " .. arg.values[3].str .. " ))"
		end
		result.str = "do{\n" .. arg.values[1].str .. "\n}\nwhile" .. condition .. "\n"
		return result
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
