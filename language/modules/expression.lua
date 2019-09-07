
OperatorClasses = {
	{
		name = "Scope",
		order = "ltr",
		operators = {
			{peg="'::'", cpp="({<})::({>})"}
		}
	}, {
		name = "Access",
		order = "ltr",
		operators = {
			{peg="'(' ~_ ')'", cpp="({<})()"},
			{peg="'(' ~_ ExpressionList ~_ ')'", cpp="({<})({1})"},
			{peg="'[' ~_ ExpressionList ~_ ']'", cpp="({<})[{1}]"},
			{peg="'.'", cpp="({<}).{>}"},
			{peg="'->'", cpp="({<})->{>}"}
		}
	}, {
		name = "Prefix",
		order = "rtl",
		operators = {
			{peg="'+'", cpp="+({>})"},
			{peg="'-'", cpp="-({>})"},
			{peg="'not'", cpp="!({>})"},
			{peg="'bitnot'", cpp="~({>})"},
			{peg="'^'", cpp="*({>})"},
			{peg="'@'", cpp="&({>})"},
			{peg="'sizeof'", cpp="sizeof({>})"}
		}
	}, {
		name = "Exponentiation",
		order = "rtl",
		operators = {
			{peg="'^'", cpp="pow(({<}), ({>}))"}
		}
	}, {
		name = "Multiplication",
		order = "ltr",
		operators = {
			{peg="'*'", cpp="({<})*({>})"},
			{peg="'/'", cpp="double({<})/double({>})"},
			{peg="'div'", cpp="int({<})/int({>})"},
			{peg="'mod'", cpp="({<})%%({>})"} -- % is the gsub escape character
		}
	}, {
		name = "Addition",
		order = "ltr",
		operators = {
			{peg="'+'", cpp="({<})+({>})"},
			{peg="'-'", cpp="({<})-({>})"}
		}
	}, {
		name = "Shifting",
		order = "ltr",
		operators = {
			{peg="'<<'", cpp="({<})<<({>})"},
			{peg="'>>'", cpp="({<})>>({>})"}
		}
	}, {
		name = "BitConjunction",
		order = "ltr",
		operators = {
			{peg="'bitand'", cpp="({<})&({>})"}
		}
	}, {
		name = "BitExclusiveDisjunction",
		order = "ltr",
		operators = {
			{peg="'bitxor'", cpp="({<})^({>})"}
		}
	}, {
		name = "BitDisjunction",
		order = "ltr",
		operators = {
			{peg="'bitor'", cpp="({<})|({>})"}
		}
	}, {
		name = "Comparison",
		order = "ltr",
		operators = {
			{peg="'=='", cpp="({<})==({>})"},
			{peg="'!='", cpp="({<})!=({>})"},
			{peg="'<='", cpp="({<})<=({>})"},
			{peg="'>='", cpp="({<})>=({>})"},
			{peg="'<'", cpp="({<})<({>})"},
			{peg="'>'", cpp="({<})>({>})"}
		}
	}, {
		name = "Conjunction",
		order = "ltr",
		operators = {
			{peg="'and'", cpp="({<})&&({>})"}
		}
	}, {
		name = "ExclusiveDisjunction",
		order = "ltr",
		operators = {
			{peg="'xor'", cpp="!({<})!=!({>})"}
		}
	}, {
		name = "Disjunction",
		order = "ltr",
		operators = {
			{peg="'or'", cpp="({<})||({>})"}
		}
	}, {
		name = "Conditional",
		order = "rtl",
		operators = {
			{peg="'?' ~_ Expression ~_ ':'", cpp="({<})? ({1}):({>})"}
		}
	}, {
		name = "Throw",
		order = "rtl",
		operators = {
			{peg="'throw'", cpp="throw ({>})"}
		}
	}
}

-- turn "{<}?{1}:{>}" into {-1, "?", 1, ":", -2} and infer unaries and binaries from the presence of {<} and {>}
opparser = pegparser{
	grammar = [[
		snippet <- (lref / mref / rref / other)*
		lref <- '{<}'
		mref <- '{' <[1-9][0-9]*> '}'
		rref <- '{>}'
		other <- <(!lref !mref !rref .)*>
	]],
	actions = {
		lref = function() return -1 end,
		mref = function(sv, info) return tonumber(info.tokens[1]) end,
		rref = function() return -2 end,
		other = function(sv, info) return info.tokens[1] end,
		snippet = function(sv, info) return sv end
	},
	default = function() return nil end
}

for ic, class in ipairs(OperatorClasses) do
	for iop, operator in ipairs(class.operators) do
		snippet = opparser:parse(operator.cpp)

		local usesl = false
		local usesr = false
		for ip, part in ipairs(snippet) do
			if part == -1 then usesl = true end
			if part == -2 then usesr = true end
		end
		if  class.order == "ltr" and usesr  or  class.order == "rtl" and usesl  then
			if class.binaries == nil then class.binaries = {} end
			table.insert(class.binaries, {peg=operator.peg, snippet=snippet})
		else
			if class.unaries == nil then class.unaries = {} end
			table.insert(class.unaries, {peg=operator.peg, snippet=snippet})
		end
	end
end

rule(" Expression <- " .. OperatorClasses[#OperatorClasses].name, basic.concat )
rule([[ ExpressionList <- Expression (_ Comma _ Expression)* ]], basic.concat )
rule([[ ExpressionListMulti <- Expression _ Comma _ Expression (_ Comma _ Expression)* ]], basic.concat )
rule([[ Atomic <- LParen _ Expression _ RParen / Identifier / Literal / Range ]], basic.concat )

-- helper function: turn {{peg='a'}, {peg='b'}, {peg='c'}} into "a / b / c"
function choice(tbl)
	if tbl == nil then return "" end
	local buf = {}
	for i, v in ipairs(tbl) do
		buf[#buf+1] = "(" .. v.peg .. ")"
	end
	return table.concat(buf, " / ")
end

-- the action for operations with left to right associativity
function ltrOperation(sv, info)
	local resultTbl = {txt=sv[1].txt}

	local i = 2
	while i <= #sv do

		local raw = ""

		for is, snippet in ipairs(sv[i].cpp) do
			if type(snippet) == "number" then
				if snippet == -1 then
					raw = raw .. resultTbl.txt
				elseif snippet == -2 then
					raw = raw .. sv[i+1].txt
				else
					raw = raw .. sv[i].args[snippet].txt
				end
			else
				raw = raw .. snippet
			end
		end
		if sv[i].typ == "u" then
			i = i+1
		elseif sv[i].typ == "b" then
			i = i+2
		else
			error("invalid operator type")
		end

		resultTbl.txt = raw
	end

	return resultTbl
end

-- the action for operations with right to left associativity
function rtlOperation(sv, info)
	local resultTbl = {txt=sv[#sv].txt}

	local i = #sv-1
	while i >= 1 do

		local raw = ""

		for is, snippet in ipairs(sv[i].cpp) do
			if type(snippet) == "number" then
				if snippet == -2 then
					raw = raw .. resultTbl.txt
				elseif snippet == -1 then
					raw = raw .. sv[i-1].txt
				else
					raw = raw .. sv[i].args[snippet].txt
				end
			else
				raw = raw .. snippet
			end
		end
		if sv[i].typ == "u" then
			i = i-1
		elseif sv[i].typ == "b" then
			i = i-2
		else
			error("invalid operator type")
		end

		resultTbl.txt = raw
	end

	return resultTbl
end

-- construct and register the actual grammar text for all operator classes
for i, v in ipairs(OperatorClasses) do
	local class = OperatorClasses[i]
	if i==1 then
		higherClass = "Atomic"
	else
		higherClass = OperatorClasses[i-1].name
	end

	local unaries = choice(class.unaries)
	local binaries = choice(class.binaries)

	local uname = class.name .. "Unary"
	local bname = class.name .. "Binary"

	if unaries ~= "" and binaries == "" then
		unaries = " " .. uname .. " <- " .. unaries
		if class.order == "ltr" then
			operation = " " .. class.name .. " <- " .. higherClass .. " ( ~_ " .. uname .. " )*"
		else
			operation = " " .. class.name .. " <- ( " .. uname .. " ~_ )* " .. higherClass
		end
	elseif unaries == "" and binaries ~= "" then
		binaries = " " .. bname .. " <- " .. binaries
		operation = " " .. class.name .. " <- " .. higherClass .. " ( ~_ " .. bname .. " ~_ " .. higherClass .. " )*"
	elseif unaries ~= "" and binaries ~= "" then
		unaries = " " .. uname .. " <- " .. unaries
		binaries = " " .. bname .. " <- " .. binaries
		if class.order == "ltr" then
			operation = " " .. class.name .. " <- " .. higherClass .. " ( ~_ " .. uname .. " / ( " .. bname .. " ~_ " .. higherClass .. " ) )*"
		else
			operation = " " .. class.name .. " <- ( " .. uname .. " / ( " .. higherClass .. " ~_ " .. bname .. " ) ~_ )* " .. higherClass
		end
	end

	if unaries ~= "" then
		rule(unaries,
			function(sv, info)
				return {typ='u', cpp=class.unaries[info.choice].snippet, args=sv}
			end, "unary"
		)
	end
	if binaries ~= "" then
	 	rule(binaries,
			function(sv, info)
				return {typ='b', cpp=class.binaries[info.choice].snippet, args=sv}
			end, "binary"
		)
	end

	if class.order == "ltr" then
		rule(operation, ltrOperation, "ltrOperation")
	else
		rule(operation, rtlOperation, "rtlOperation")
	end
end
