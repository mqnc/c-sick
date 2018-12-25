
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


--rule([[ ForStatement <- {CountingForLoop} / {IteratorLoop} ]], basic.subs )
rule([[ ForStatement <- {CountingForLoop} ]], basic.subs )
rule([[ CountingForLoop <- ForKeyword _ {CountingRange} _ break {ForBody} EndForKeyword ]],
	function(arg)
		local result = sv(arg)
		result.str = "for" .. arg.values[1].str .. "{\n" .. arg.values[2].str .. "\n}\n"
		return result
	end
)
rule([[ ForKeyword <- 'for' ]])
table.insert(keywords, "ForKeyword")
rule([[ CountingRange <- {DoubleComparison} (_ ',' _ {Expression})? ]],
	function(arg)
		local result = sv(arg)
		local dblcmp = arg.values[1].values
		local lim1 = dblcmp[1].str
		local rel1 = dblcmp[2].str
		local var = dblcmp[3].str
		local rel2 = dblcmp[4].str
		local lim2 = dblcmp[5].str

		result.str = "(auto " .. var .. "=" .. lim1
		if rel1 == "<" then
			result.str = result.str .. "+1"
		elseif rel1 == ">" then
			result.str = result.str .. "-1"
		end
		result.str = result.str .. "; " .. var .. rel2 .. lim2 .. "; "

		if arg.values[2] then
			result.str = result.str .. var .. "=" .. arg.values[2].str .. ")"
		elseif rel2 == "<" or rel2 == "<=" then
			result.str = result.str .. var .. "++)"
		else
			result.str = result.str .. var .. "--)"
		end

		return result
	end
)
rule([[ DoubleComparison <- {Atomic} _ {Relation} _ {Identifier} _ {Relation} _ {Atomic} ]], basic.forward )
rule([[ Relation <- "<=" / "<" / ">=" / ">" ]], basic.match )
rule([[ ForBody <- {skip} (!EndForKeyword {LocalStatement} {skip})* ]], basic.subs )
rule([[ EndForKeyword <- 'end' ]])
table.insert(keywords, "EndForKeyword")
table.insert(localStatements, "{ForStatement}")
