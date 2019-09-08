
rule([[ Range <- RangeL _ Expression _ RangeOperator _ (Expression _ RangeOperator _ )? Expression? _ RangeR ]], function(sv, info)

	local inclStart = sv[1].choice
	local startValue = sv[3].txt
	local finalValue = nil
	if #sv == 13 or #sv == 9 then
		finalValue = sv[#sv-2].txt
	end
	local increment = "1"
	if #sv == 13 or #sv == 12 then
		increment = sv[7].txt
	end
	local inclEnd = sv[#sv].choice

	if finalValue == nil then
		return {txt = "Range(" .. inclStart .. ", " .. startValue .. ", " .. increment .. ")"}
	else
		return {txt = "Range(" .. inclStart .. ", " .. startValue .. ", " .. increment .. ", " .. finalValue .. ", " .. inclEnd .. ")"}
	end
end)

rule([[ RangeL <- LBracket / LParen ]], basic.choice("true", "false"))
rule([[ RangeR <- RBracket / RParen ]], basic.choice("true", "false"))

rule([[ RangeOperator <- ".." ]])
