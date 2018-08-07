
grammar = {}
actions = {}

function rule(r)
	grammar[1 + #grammar] = r
end

rule("Add <- (Num '+')* Num")
rule("Num <- [0-9]+")

actions["Add"] = function(params)
	res = 0
	for i,term in pairs(params.values) do
		res = res + term
	end
	return res
end

function default(params)
    return params.matched
end

--parser = new peglib.parser(table.concat(grammar, "\n"), actions, default)
--value = parser.parse(sys.stdin)

pp = parser(table.concat(grammar, "\n"), actions, default)

parse(pp, "3+4+15")
