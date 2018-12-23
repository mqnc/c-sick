

rule([[ IfStatement <- {IfPart} ({ElseIfPart})* {ElsePart}? EndIfKeyword _ break ]], basic.concat )
rule([[ IfPart <- IfKeyword _ {Condition} _ break {IfBody} ]], "if( {1} ){\n{2}\n}\n" )
rule([[ IfKeyword <- 'if' ]])
table.insert(keywords, "IfKeyword")
rule([[ Condition <- {Expression} ]], basic.subs )
rule([[ IfBody <- {skip} (!ElseIfKeyword !ElseKeyword !EndIfKeyword {LocalStatement} {skip})* ]], basic.subs )
rule([[ ElseIfPart <- ElseIfKeyword _ {Condition} _ break {IfBody} ]], "else if( {1} ){\n{2}\n}\n" )
rule([[ ElseIfKeyword <- 'elseif' ]])
table.insert(keywords, "ElseIfKeyword")
rule([[ ElsePart <- ElseKeyword _ break {IfBody} ]], "else{\n{1}\n}\n" )
rule([[ ElseKeyword <- 'else' ]])
table.insert(keywords, "ElseKeyword")
rule([[ EndIfKeyword <- 'end' ]])
table.insert(keywords, "EndIfKeyword")

table.insert(localStatements, "{IfStatement}")


rule([[ SwitchStatement <- SwitchKeyword _ {Expression} _ break skip ({Case} skip)* EndSwitchKeyword ]],
	function(arg)
		local result = sv(arg)
		local buf = ss()
		for i = 2, #arg.values do
			append(buf, arg.values[i].str)
		end
		result.str = "switch(" .. arg.values[1].str .. "){\n" .. join(buf) .. "\n}\n"
		return result
	end
)
rule([[ SwitchKeyword <- 'switch' ]])
table.insert(keywords, "SwitchKeyword")
rule([[ Case <- ({CaseCondition} / {DefaultKeyword}) break {OptionalCaseBody} ({FallKeyword} _ break)? skip ]],
	function(arg)
		local result = sv(arg)
		result.str = arg.values[1].str .. "\n" .. arg.values[2].str .. "\n"
		if #arg.values == 2 then -- no fall keyword
			result.str = result.str .. "break;\n"
		end
		return result
	end
)
rule([[ CaseCondition <- CaseKeyword _ ({Expression} / {DefaultKeyword}) _ (',' _ ({Expression} / {DefaultKeyword}) _)* ]],
	function(arg)
		local result = sv(arg)
		for i, val in ipairs(arg.values) do
			if val.rule == "DefaultKeyword" then
				result.str = result.str .. val.str
			else
				result.str = result.str .. "case(" .. val.str .. "): "
			end
		end
		return result
	end
)
rule([[ CaseKeyword <- 'case' ]])
table.insert(keywords, "CaseKeyword")
rule([[ FallKeyword <- 'fall' ]])
table.insert(keywords, "FallKeyword")
rule([[ DefaultKeyword <- 'default' ]], "default: " )
table.insert(keywords, "DefaultKeyword")
rule([[ EndSwitchKeyword <- 'end' ]])
table.insert(keywords, "EndSwitchKeyword")
rule([[ OptionalCaseBody <- {skip} (!FallKeyword !CaseKeyword !DefaultKeyword !EndSwitchKeyword {LocalStatement} {skip})* ]], basic.subs )

table.insert(localStatements, "{SwitchStatement}")
