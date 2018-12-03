
OperatorClasses = {
	{
		name = "Scope",
		order = "ltr",
		operators = {
			{peg="'::'", cpp="(<#)::(#>)"}
		}
	}, {
		name = "Access",
		order = "ltr",
		operators = {
			{peg="'(' ~_ Expression ~_ ')'", cpp="(<#)(#1)"},
			{peg="'[' ~_ Expression ~_ ']'", cpp="(<#)[#1]"},
			{peg="'.'", cpp="(<#).#>"},
			{peg="'->'", cpp="(<#)->#>"}
		}
	}, {
		name = "Prefix",
		order = "rtl",
		operators = {
			{peg="'+'", cpp="+(#>)"},
			{peg="'-'", cpp="-(#>)"},
			{peg="'not'", cpp="!(#>)"},
			{peg="'bitnot'", cpp="~(#>)"},
			{peg="'^'", cpp="*(#>)"},
			{peg="'@'", cpp="&(#>)"},
			{peg="'sizeof'", cpp="sizeof(#>)"}
		}
	}, {
		name = "Exponentiation",
		order = "rtl",
		operators = {
			{peg="'^'", cpp="pow((<#), (#>))"}
		}
	}, {
		name = "Multiplication",
		order = "ltr",
		operators = {
			{peg="'*'", cpp="(<#)*(#>)"},
			{peg="'/'", cpp="double(<#)/double(#>)"},
			{peg="'div'", cpp="int(<#)/int(#>)"},
			{peg="'mod'", cpp="(<#)%(#>)"}
		}
	}, {
		name = "Addition",
		order = "ltr",
		operators = {
			{peg="'+'", cpp="(<#)+(#>)"},
			{peg="'-'", cpp="(<#)-(#>)"}
		}
	}, {
		name = "Shifting",
		order = "ltr",
		operators = {
			{peg="'<<'", cpp="(<#)<<(#>)"},
			{peg="'>>'", cpp="(<#)>>(#>)"}
		}
	}, {
		name = "BitConjunction",
		order = "ltr",
		operators = {
			{peg="'bitand'", cpp="(<#)&(#>)"}
		}
	}, {
		name = "BitExclusiveDisjunction",
		order = "ltr",
		operators = {
			{peg="'bitxor'", cpp="(<#)^(#>)"}
		}
	}, {
		name = "BitDisjunction",
		order = "ltr",
		operators = {
			{peg="'bitor'", cpp="(<#)|(#>)"}
		}
	}, {
		name = "Comparison",
		order = "ltr",
		operators = {
			{peg="'=='", cpp="(<#)==(#>)"},
			{peg="'!='", cpp="(<#)!=(#>)"},
			{peg="'<'", cpp="(<#)<(#>)"},
			{peg="'<='", cpp="(<#)<=(#>)"},
			{peg="'>'", cpp="(<#)>(#>)"},
			{peg="'>='", cpp="(<#)>=(#>)"}
		}
	}, {
		name = "Conjunction",
		order = "ltr",
		operators = {
			{peg="'and'", cpp="(<#)&&(#>)"}
		}
	}, {
		name = "ExclusiveDisjunction",
		order = "ltr",
		operators = {
			{peg="'xor'", cpp="!(<#)!=!(#>)"}
		}
	}, {
		name = "Disjunction",
		order = "ltr",
		operators = {
			{peg="'or'", cpp="(<#)||(#>)"}
		}
	}, {
		name = "Conditional",
		order = "rtl",
		operators = {
			{peg="'?' ~_ Conditional ~_ ':'", cpp="(<#)? (#1):(#>)"}
		}
	}, {
		name = "Throw",
		order = "rtl",
		operators = {
			{peg="'throw'", cpp="throw (#>)"}
		}
	}
}



-- turn "(#1)+(#2)" into {"(", 1, ")+(", 2, ")"} and infer unaries and binaries from operators

opparser = pegparser{
	grammar = [[
		snippet <- (lref / mref / rref / other)*
		lref <- '<#'
		mref <- '#'<[1-9][0-9]*>
		rref <- '#>'
		other <- (!lref !mref !rref .)*
	]],
	actions = {
		lref = function(params) return -1 end,
		mref = function(params) return tonumber(params.tokens[1]) end,
		rref = function(params) return -2 end,
		other = function(params) return params.matched end,
		snippet = function(params) return params.values end
	},
	default = function(params) return nil end,
	packrat = false,
	debuglog = false
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

grammar = {}
actions = {}

debuglog = false
packrat = not debuglog

function rule(r)
	grammar[1 + #grammar] = r
end

rule([[Expression <- ]] .. OperatorClasses[#OperatorClasses].name)
rule([[Atomic <- '(' ~_ Expression ~_ ')' / Identifier / [0-9]+]])

function choice(tbl)
	local result = ""
	if tbl == nil then
		return result
	end

	local first = true
	for i, v in ipairs(tbl) do
		if first then
			first = false
		else
			result = result .. " / "
		end
		result = result .. "(" .. v.peg .. ")"
	end
	return result
end


function ltrOperation(params)
	--print(params.rule .. ": " .. stringify(params))

	local result = params.values[1]

	local i = 2

	while i <= #params.values do

		local raw = ""

		for is, snippet in ipairs(params.values[i].cpp) do
			if type(snippet) == "number" then
				if snippet == -1 then
					raw = raw .. result
				elseif snippet == -2 then
					raw = raw .. params.values[i+1]
				else
					raw = raw .. params.values[i].args[snippet]
				end
			else
				raw = raw .. snippet
			end
		end
		if params.values[i].typ == "u" then
			i = i+1
		elseif params.values[i].typ == "b" then
			i = i+2
		else
			error("invalid operator type")
		end

		result = raw
	end

	return result
end

function rtlOperation(params)
	--print(params.rule .. ": " .. stringify(params))

	result = params.values[1]

	local i = #params.values-1

	while i >= 1 do

		local raw = ""

		for is, snippet in ipairs(params.values[i].cpp) do
			if type(snippet) == "number" then
				if snippet == -2 then
					raw = raw .. result
				elseif snippet == -1 then
					raw = raw .. params.values[i-1]
				else
					raw = raw .. params.values[i].args[snippet]
				end
			else
				raw = raw .. snippet
			end
		end
		if params.values[i].typ == "u" then
			i = i-1
		elseif params.values[i].typ == "b" then
			i = i-2
		else
			error("invalid operator type")
		end

		result = raw
	end

	return result
end


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
		unaries = uname .. " <- " .. unaries .. "\n"
		if class.order == "ltr" then			
			operation = class.name .. ": ltrOperation <- " .. higherClass .. " ( ~_ " .. uname .. " )*"
		else
			operation = class.name .. ": rtlOperation <- ( " .. uname .. " ~_ )* " .. higherClass .. ""
		end
	elseif unaries == "" and binaries ~= "" then
		binaries = bname .. " <- " .. binaries .. "\n"
		operation = class.name .. ": " .. class.order .. "Operation <- " .. higherClass .. " ( ~_ " .. bname .. " ~_ " .. higherClass .. " )*"
	elseif unaries ~= "" and binaries ~= "" then
		unaries = uname .. " <- " .. unaries .. "\n"
		binaries = bname .. " <- " .. binaries .. "\n"
		if class.order == "ltr" then
			operation = class.name .. ": ltrOperation <- " .. higherClass .. " ( ~_ " .. uname .. " / ( " .. bname .. " ~_ " .. higherClass .. " ) )*"
		else
			operation = class.name .. ": rtlOperation <- ( " .. uname .. " / ( " .. higherClass .. " ~_ " .. bname .. " ) ~_ )* " .. higherClass .. ""
		end
	end
	
	rule(unaries .. binaries .. operation)

	actions[uname] = function(params)
		return {typ='u', cpp=class.unaries[params.choice].snippet, args=params.values}
	end

	actions[bname] = function(params)
		return {typ='b', cpp=class.binaries[params.choice].snippet, args=params.values}
	end

end

print(table.concat(grammar, "\n"))

