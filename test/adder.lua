
grammar = {}
actions = {}

function rule(r)
	grammar[1 + #grammar] = r
end

rule("Add <- (Num '+')* Num")

actions["Add"] = function(params)
	res = 0
	for term in params.subnodes do
		res = res + term
	end
	return res
end

function default(params)
    return params.matched
end

parser = new peglib.parser(table.concat(grammar, "\n"), actions, default)

value = parser.parse(sys.stdin)