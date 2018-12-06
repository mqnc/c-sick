
local transpiler = require "transpiler"
rule = transpiler.rule
basic = transpiler.basicActions

add = function(params)
	res = 0
	for i,term in pairs(params.values) do
		res = res + term.output
	end
	return res
end

rule( [[ Add <- ws ( {Num} ws '+' ws)* {Num} ws ]], add )
rule( [[ Num <- [0-9]+ ]], basic.match )
rule( [[ ws <- ' '* ]] )

print(transpiler.grammar())
local debug = true
print(transpiler.transpile("3+4+5", debug))


transpiler.clear()

rule( [[ html <- ({tag} / {text})* ]], basic.subs )
rule( [[ tag <- "<" {word} ">" {html} "</" {word} ">" ]], "(open:{1}, inner:{2}, close:{3})" )
rule( [[ text <- (word / " ")+ ]], basic.match )
rule( [[ word <- [a-zA-Z]+ ]], basic.match )

print(transpiler.grammar())
print(transpiler.transpile("look at this <b>fat <i>italic</I></B> pizza"))
