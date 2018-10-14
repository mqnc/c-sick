

grammar = {}
actions = {}

input = "3*-4+5*6++7"

debuglog = false
packrat = not debuglog

function rule(r)
	grammar[1 + #grammar] = r
end



rule([[ Expression <- Addition ]])
rule([[ Atomic <- [0-9]* ]])

Prefix = {name = "Prefix", order = "rtl", unaries = {["+"] = "pos", ["-"] = "neg"}, binaries = {}}
Multi = {name = "Multiplication", order = "ltr", unaries = {["!"] = "fac"}, binaries = {["*"] = "mul", ["/"] = "div"}}
Addi = {name = "Addition", order = "ltr", unaries = {}, binaries = {["+"] = "add", ["-"] = "sub"}}

OperatorClasses = {Prefix, Multi, Addi}

function choice(tbl)
	result = ""
	first = true
	for k, v in pairs(tbl) do
		if first then
			first = false
		else
			result = result .. " / "
		end
		result = result .. "'" .. k .. "'"
	end
	return result
end

function ltrOperation(params)



end

for i, v in ipairs(OperatorClasses) do
	class = OperatorClasses[i]
	if i==1 then
		higherClass = "Atomic"
	else
		higherClass = OperatorClasses[i-1].name
	end

	unaries = choice(class.unaries)
	binaries = choice(class.binaries)
	operation = ""
	ruleset = ""

	uname = class.name .. "Unary"
	bname = class.name .. "Binary"

	hcltr = ""
	hcrtl = ""

	if class.order == "ltr" then
		hcltr = " " .. higherClass .. " "
	elseif class.order == "rtl" then
		hcrtl = " " .. higherClass .. " "
	end

	if unaries:len() > 0 and binaries:len() == 0 then
		unaries = uname .. " <- " .. unaries .. "\n"
		operation = operation .. " " .. uname .. "*"
	elseif unaries:len() == 0 and binaries:len() > 0 then
		binaries = bname .. " <- " .. binaries .. "\n"
		operation = operation .. " (" .. hcrtl .. bname .. hcltr .. ")*"
	elseif unaries:len() > 0 and binaries:len() > 0 then
		unaries = uname .. " <- " .. unaries .. "\n"
		binaries = bname .. " <- " .. binaries .. "\n"
		operation = operation .. " (" .. uname .. " / (" .. hcrtl .. bname .. hcltr .. "))*"
	end

	operation = class.name .. " <- " .. hcltr .. operation .. hcrtl

	rule(unaries .. binaries .. operation)

	actions[uname] = function(params)
		return {op=params.matched, typ="u", call=class.unaries[params.matched]}
	end

	actions[bname] = function(params)
		return {op=params.matched, typ="b", call=class.binaries[params.matched]}
	end

end


print(table.concat(grammar, "\n"))
print("\n")
print(stringify(actions))
print("\n")

function default(params)
	return params.matched
end

actions["Addition"] = function(params)
	print(stringify(params))
	return params.matched
end


pp = pegparser{
	grammar = table.concat(grammar, "\n"),
	actions = actions,
	default = default,
	packrat = packrat,
	debuglog = debuglog}

output = pp:parse(input)

print(output)

