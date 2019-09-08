
rule([[ WhileStatement <- WhileKeyword _ Expression _ SilentTerminal LoopBody EndKeyword ]], function(sv, info)
	local condition = sv[3].txt
	local body = sv[6]
	local betweenbody = "\n"
	if #body == 3 then
		betweenbody = body[3].txt
	end

	local result = "if(" .. condition .. "){\nwhile(true){\n" .. body[1].txt ..
			"\nif(!(" .. condition .. ")){break;}\n" .. betweenbody .. "}\n}\n"

	return {txt=result}
end )
table.insert(localStatements, "WhileStatement")

rule([[ RepeatStatement <- RepeatKeyword _ SilentTerminal LoopBody RepeatCondition ]], function(sv, info)
	local body = sv[4]
	local condition = sv[5][1].txt
	local betweenbody = "\n"
	if #body == 3 then
		betweenbody = body[3].txt
	end

	local result = "while(true){\n" .. body[1].txt ..
			"\nif(" .. condition .. "){break;}\n" .. betweenbody .. "}\n"

	return {txt=result}
end )
table.insert(localStatements, "RepeatStatement")

rule([[ ForStatement <- ForKeyword _ (SimpleDeclaree / Expression) _ InKeyword _ Expression _ SilentTerminal LoopBody EndKeyword ]], function(sv, info)
	local iterator = sv[3].txt
	local range = sv[7].txt
	local body = sv[10]
	local betweenbody = "\n"
	if #body == 3 then
		betweenbody = body[3].txt
	end
	local rangeref = mark .. "range"

	local result = "{\nauto " .. rangeref .. " = " .. range .. ".save();\nif(!" .. rangeref .. ".empty()){\nwhile(true){\n" ..
			iterator .. " = " .. rangeref .. ".front();\n" .. body[1].txt .. "\n" .. rangeref .. ".popFront();\n" ..
			"if(" .. rangeref .. ".empty()){break;}\n" .. betweenbody .. "\n}\n}\n}\n"

	return {txt=result}
end )
table.insert(localStatements, "ForStatement")


rule([[ LoopBody <- IterationBody (BetweenKeyword IterationBody)? ]], basic.tree )
rule([[ IterationBody <- Skip (!BetweenKeyword !EndKeyword !RepWhileKeyword !UntilKeyword LocalStatement Skip)* ]], basic.concat )

rule([[ RepeatCondition <- RepWhileCondition / UntilCondition ]], basic.tree)
rule([[ RepWhileCondition <- RepWhileKeyword _ Expression _ SilentTerminal ]], "!({3})")
rule([[ UntilCondition <- UntilKeyword _ Expression _ SilentTerminal ]], "{3}")

rule([[ WhileKeyword <- 'while' ]])
table.insert(keywords, "WhileKeyword")
rule([[ BetweenKeyword <- 'between' ]])
table.insert(keywords, "BetweenKeyword")
rule([[ RepeatKeyword <- 'repeat' ]])
table.insert(keywords, "RepeatKeyword")
rule([[ RepWhileKeyword <- 'whilst' ]])
table.insert(keywords, "RepWhileKeyword")
rule([[ UntilKeyword <- 'until' ]])
table.insert(keywords, "UntilKeyword")
rule([[ ForKeyword <- 'for' ]])
table.insert(keywords, "ForKeyword")
rule([[ InKeyword <- 'in' ]])
table.insert(keywords, "InKeyword")
