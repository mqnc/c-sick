
rule([[ Range <- RangeL _ Expression _ RangeOperator _ (IncrementOperator _ Expression _ RangeOperator _ )? RangeEnd _ RangeR ]], function(sv, info)

	local openStart = sv[1].choice
	local initialValue = sv[3].txt

	local incrementOperator
	local increment

	local finalValue = sv[#sv-2]
	local openEnd = sv[#sv].choice

	if #sv == 9 then -- inc by 1
		incrementOperator = "ADD"
		increment = "1"
	else -- custom increment
		incrementOperator = sv[7].choice
		increment = sv[9].txt
	end

	local result = "Range(RangeOpenness::" .. openStart .. ", " .. initialValue .. ", RangeIncOp::" .. incrementOperator .. ", " .. increment

	if finalValue.choice == "inf" then
		result = result .. ")"
	else
		result = result .. ", RangeOpenness::" .. openEnd .. ", " .. finalValue.txt .. ")"
	end

	return {txt=result}
end)

rule([[ RangeL <- LBracket / LParen ]], basic.choice("CLOSED", "OPEN"))
rule([[ RangeR <- RBracket / RParen ]], basic.choice("CLOSED", "OPEN"))

rule([[ IncrementOperator <- "+=" / "-=" / "*=" / "/=" ]], basic.choice("ADD", "SUB", "MUL", "DIV"))
rule([[ RangeOperator <- ".." ]])

rule([[ RangeEnd <- Expression / '' ]], basic.choice("fin", "inf"))
