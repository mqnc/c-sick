
input = "3*-4+5*6++7+1*2*3"
--input = "1*2+3*4+5*6*7"
input = "11?22:33?44(41):55"

-- TODO: infer "unaries" and "binaries" from <# and #>, maybe write a complete grammar for the operator definition

Scope = {name = "Scope", order = "ltr",
	binaries = {
		{"'::'", "(<#)::(#>)"}
	}
}

Access = {name = "Access", order = "ltr",
	unaries = {
		{"'(' Expression ')'", "(<#)(#1)"},
		{"'[' Expression ']'", "(<#)[#1]"}
	},
	binaries = {
		{"'.'", "(<#).#>"},
		{"'->'", "(<#)->#>"}
	}
}

Prefix = {name = "Prefix", order = "rtl",
	unaries = {
		{"'+'", "+(#>)"},
		{"'-'", "-(#>)"},
		{"'not'", "!(#>)"},
		{"'bitnot'", "~(#>)"},
		{"'^'", "*(#>)"},
		{"'@'", "&(#>)"},
		{"'sizeof'", "sizeof(#>)"}
	}
}

Exponentiation = {name = "Exponentiation", order = "rtl",
	binaries = {
		{"'^'", "pow((<#), (#>))"}
	}
}

Multiplication = {name = "Multiplication", order = "ltr",
	binaries = {
		{"'*'", "(<#)*(#>)"},
		{"'/'", "double(<#)/double(#>)"},
		{"'div'", "int(<#)/int(#>)"},
		{"'mod'", "(<#)%(#>)"}
	}
}

Addition = {name = "Addition", order = "ltr",
	binaries = {
		{"'+'", "(<#)+(#>)"},
		{"'-'", "(<#)-(#>)"}
	}
}

Shifting = {name = "Shifting", order = "ltr",
	binaries = {
		{"'<<'", "(<#)<<(#>)"},
		{"'>>'", "(<#)>>(#>)"}
	}
}

BitConjunction = {name = "BitConjunction", order = "ltr",
	binaries = {
		{"'bitand'", "(<#)&(#>)"}
	}
}

BitExclusiveDisjunction = {name = "BitExclusiveDisjunction", order = "ltr",
	binaries = {
		{"'bitxor'", "(<#)^(#>)"}
	}
}

BitDisjunction = {name = "BitDisjunction", order = "ltr",
	binaries = {
		{"'bitor'", "(<#)|(#>)"}
	}
}

Comparison = {name = "Comparison", order = "ltr",
	binaries = {
		{"'=='", "(<#)==(#>)"},
		{"'!='", "(<#)!=(#>)"},
		{"'<'", "(<#)<(#>)"},
		{"'<='", "(<#)<=(#>)"},
		{"'>'", "(<#)>(#>)"},
		{"'>='", "(<#)>=(#>)"}
	}
}

Conjunction = {name = "Conjunction", order = "ltr",
	binaries = {
		{"'and'", "(<#)&&(#>)"}
	}
}

ExclusiveDisjunction = {name = "ExclusiveDisjunction", order = "ltr",
	binaries = {
		{"'xor'", "!(<#)!=!(#>)"}
	}
}

Disjunction = {name = "Disjunction", order = "ltr",
	binaries = {
		{"'or'", "(<#)||(#>)"}
	}
}

Conditional = {name = "Conditional", order = "rtl",
	binaries = {
		{"'?' Conditional ':'", "(<#)? (#1):(#>)"}
	}
}

Throw = {name = "Throw", order = "rtl",
	unaries = {
		{"'throw'", "throw (#>)"}
	}
}

OperatorClasses = {
	Scope,
	Access,
	Prefix,
	Exponentiation,
	Multiplication,
	Addition,
	Shifting,
	BitConjunction,
	BitExclusiveDisjunction,
	BitDisjunction,
	Comparison,
	Conjunction,
	ExclusiveDisjunction,
	Disjunction,
	Conditional,
	Throw
}





function dump(obj)
	print(stringify(obj))
end

-- turn "(#1)+(#2)" into {"(", 1, ")+(", 2, ")", max=2}

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
	if class.unaries ~= nil then
		for iu, unary in ipairs(class.unaries) do
			unary.snippet = opparser:parse(unary[2])
		end
	end
	if class.binaries ~= nil then
		for ib, binary in ipairs(class.binaries) do
			binary.snippet = opparser:parse(binary[2])
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
rule([[Atomic <- '(' Expression ')' / '[' Expression ']' / [0-9]*]])

function choice(tbl)
	result = ""
	if tbl == nil then
		return result
	end

	first = true
	for i, v in ipairs(tbl) do
		if first then
			first = false
		else
			result = result .. " / "
		end
		result = result .. "(" .. v[1] .. ")"
	end
	return result
end

function ltrOperation(params)
	--print(params.rule .. ": " .. stringify(params))
	vals = params.values

	result = vals[1]

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
	vals = params.values

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
		hcltr = " " .. higherClass .. " "
	elseif class.order == "rtl" then
		hcrtl = " " .. higherClass .. " "
	end

	if unaries ~= "" and binaries == "" then
		unaries = uname .. " <- " .. unaries .. "\n"
		operation = operation .. " " .. uname .. "*"
	elseif unaries == "" and binaries ~= "" then
		binaries = bname .. " <- " .. binaries .. "\n"
		operation = operation .. " (" .. hcrtl .. bname .. hcltr .. ")*"
	elseif unaries ~= "" and binaries ~= "" then
		unaries = uname .. " <- " .. unaries .. "\n"
		binaries = bname .. " <- " .. binaries .. "\n"
		operation = operation .. " (" .. uname .. " / (" .. hcrtl .. bname .. hcltr .. "))*"
	end

	operation = class.name .. " <- " .. hcltr .. operation .. hcrtl

	rule(unaries .. binaries .. operation)

	actions[uname] = function(params)
		return {typ='u', cpp=class.unaries[params.choice].snippet, args=params.values}
	end

	actions[bname] = function(params)
		return {typ='b', cpp=class.binaries[params.choice].snippet, args=params.values}
	end

	if class.order == "ltr" then
		actions[class.name] = ltrOperation
	elseif class.order == "rtl" then
		actions[class.name] = rtlOperation
	end

end

print(table.concat(grammar, "\n"))

function default(params)
	return params.matched
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
