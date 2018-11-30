
input = "3*-4+5*6++7+1*2*3"
--input = "1*2+3*4+5*6*7"
input = "11?22:33?44(41):55"

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
			{peg="'(' _ Expression _ ')'", cpp="(<#)(#1)"},
			{peg="'[' _ Expression _ ']'", cpp="(<#)[#1]"},
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
			{peg="'?' _ Conditional _ ':'", cpp="(<#)? (#1):(#>)"}
		}
	}, {
		name = "Throw",
		order = "rtl",
		operators = {
			{peg="'throw'", cpp="throw (#>)"}
		}
	}
}





function dump(obj)
	print(stringify(obj))
end

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
		["lref"] = function(params) return -1 end,
		["mref"] = function(params) return tonumber(params.tokens[1]) end,
		["rref"] = function(params) return -2 end,
		["other"] = function(params) return params.matched end,
		["snippet"] = function(params) return params.values end
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

print(input)

debuglog = false
packrat = not debuglog

function rule(r)
	grammar[1 + #grammar] = r
end

rule([[Expression <- ]] .. OperatorClasses[#OperatorClasses].name)
rule([[Atomic <- '(' _ Expression _ ')' / '[' _ Expression _ ']' / [0-9]*]])
rule([[_ <- ' '*]])

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

function stripWs(tbl)
	local result={}

	for i, field in ipairs(tbl) do
		if not field.ws then		
			table.insert(result, field)
		end
	end

	return result
end

function ltrOperation(params)
	--print(params.rule .. ": " .. stringify(params))

	vals = stripWs(params.values)

	local result = vals[1]

	local i = 2

	while i <= #vals do

		local raw = ""

		for is, snippet in ipairs(vals[i].cpp) do
			if type(snippet) == "number" then
				if snippet == -1 then
					raw = raw .. result
				elseif snippet == -2 then
					raw = raw .. vals[i+1]
				else
					raw = raw .. vals[i].args[snippet]
				end
			else
				raw = raw .. snippet
			end
		end
		if vals[i].typ == "u" then
			i = i+1
		elseif vals[i].typ == "b" then
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

	vals = stripWs(params.values)

	result = vals[1]

	local i = #vals-1

	while i >= 1 do

		local raw = ""

		for is, snippet in ipairs(vals[i].cpp) do
			if type(snippet) == "number" then
				if snippet == -2 then
					raw = raw .. result
				elseif snippet == -1 then
					raw = raw .. vals[i-1]
				else
					raw = raw .. vals[i].args[snippet]
				end
			else
				raw = raw .. snippet
			end
		end
		if vals[i].typ == "u" then
			i = i-1
		elseif vals[i].typ == "b" then
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
	local operation = ""
	local ruleset = ""

	local uname = class.name .. "Unary"
	local bname = class.name .. "Binary"

	local hcltr = ""
	local hcrtl = ""

	if class.order == "ltr" then
		hcltr = " _ " .. higherClass .. " _ "
	elseif class.order == "rtl" then
		hcrtl = " _ " .. higherClass .. " _ "
	end

	if unaries ~= "" and binaries == "" then
		unaries = uname .. " <- " .. unaries .. "\n"
		operation = operation .. " ( _ " .. uname .. ")*"
	elseif unaries == "" and binaries ~= "" then
		binaries = bname .. " <- " .. binaries .. "\n"
		operation = operation .. " ( _ " .. hcrtl .. bname .. hcltr .. " )*"
	elseif unaries ~= "" and binaries ~= "" then
		unaries = uname .. " <- " .. unaries .. "\n"
		binaries = bname .. " <- " .. binaries .. "\n"
		operation = operation .. " ( _ " .. uname .. " / ( _ " .. hcrtl .. bname .. hcltr .. "))*"
	end

	operation = class.name .. " <- " .. hcltr .. operation .. hcrtl

	rule(unaries .. binaries .. operation)

	actions[uname] = function(params)
		return {typ='u', cpp=class.unaries[params.choice].snippet, args=stripWs(params.values)}
	end

	actions[bname] = function(params)
		return {typ='b', cpp=class.binaries[params.choice].snippet, args=stripWs(params.values)}
	end

	if class.order == "ltr" then
		actions[class.name] = ltrOperation
	elseif class.order == "rtl" then
		actions[class.name] = rtlOperation
	end

end

print(table.concat(grammar, "\n"))

function default(params)
	--dump(params)
	return params.matched
end

actions["_"] = function(params)
	return {["ws"] = true}
end

actions["Expression"] = function(params)
	return params.values[1]
end

pp = pegparser{
	grammar = table.concat(grammar, "\n"),
	actions = actions,
	default = default,
	packrat = packrat,
	debuglog = debuglog}

output = pp:parse(input)

print(output)
