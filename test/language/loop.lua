
rule([[ WhileStatement <- ~WhileKeyword _ Expression _ SilentTerminal WhileBody ~EndWhileKeyword ]], 'while( {1}{2}{3} ){4}{\n{5}\n}\n' )
rule([[ WhileKeyword <- 'while' ]])
table.insert(keywords, "WhileKeyword")
rule([[ WhileBody <- Skip (!EndWhileKeyword LocalStatement Skip)* ]], basic.concat )
rule([[ EndWhileKeyword <- 'end' ]])
table.insert(keywords, "EndWhileKeyword")

table.insert(localStatements, "WhileStatement")


rule([[ RepeatStatement <- ~RepeatKeyword _ SilentTerminal RepeatBody RepeatCondition ]], 'do{1}{2}{\n{3}\n}\n{4}' )
rule([[ RepeatKeyword <- 'repeat' ]])
table.insert(keywords, "RepeatKeyword")
rule([[ RepeatBody <- Skip (!RepWhileKeyword !UntilKeyword LocalStatement Skip)* ]], basic.concat )
rule([[ RepeatCondition <- RepWhileCondition / UntilCondition ]], basic.first )
rule([[ RepWhileCondition <- ~RepWhileKeyword _ Expression _ SilentTerminal ]], 'while( {1}{2}{3} ){4}' )
rule([[ RepWhileKeyword <- 'whilst' ]])
table.insert(keywords, "RepWhileKeyword")
rule([[ UntilCondition <- ~UntilKeyword _ Expression _ SilentTerminal ]], 'while(!( {1}{2}{3} )){4}' )
rule([[ UntilKeyword <- 'until' ]])
table.insert(keywords, "UntilKeyword")

table.insert(localStatements, "RepeatStatement")


--rule([[ ForStatement <- CountingForLoop / IteratorLoop ]], basic.subs )
rule([[ ForStatement <- CountingForLoop ]], basic.first )
rule([[ CountingForLoop <- ~ForKeyword _ CountingRange _ SilentTerminal ForBody ~EndForKeyword ]], 'for {1}{2}{3}{4}{\n{5}\n}\n' )
rule([[ ForKeyword <- 'for' ]])
table.insert(keywords, "ForKeyword")
rule([[ CountingRange <- DoubleComparison (~_ ',' ~_ Expression)? ]],
	function(arg)
		log(arg)

		local result = ""
		local dblcmp = arg.values[1].values
		local lim1 = dblcmp[1][1]
		local rel1 = dblcmp[2][1]
		local var = dblcmp[3][1]
		local rel2 = dblcmp[4][1]
		local lim2 = dblcmp[5][1]

		result = "(auto " .. var .. "=" .. lim1
		if rel1 == "<" then
			result = result .. "+1"
		elseif rel1 == ">" then
			result = result .. "-1"
		end
		result = result .. "; " .. var .. rel2 .. lim2 .. "; "

		if arg.values[2] then
			result = result .. var .. "=" .. arg.values[2][1] .. ")"
		elseif rel2 == "<" or rel2 == "<=" then
			result = result .. var .. "++)"
		else
			result = result .. var .. "--)"
		end

		return {result}
	end
)
rule([[ DoubleComparison <- Atomic ~_ Relation ~_ Identifier ~_ Relation ~_ Atomic ]], basic.tree )
rule([[ Relation <- "<=" / "<" / ">=" / ">" ]], basic.match )
rule([[ ForBody <- Skip (!EndForKeyword LocalStatement Skip)* ]], basic.concat )
rule([[ EndForKeyword <- 'end' ]])
table.insert(keywords, "EndForKeyword")

table.insert(localStatements, "ForStatement")
