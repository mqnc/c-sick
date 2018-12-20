
-- the assertion is outsourced to the user

local utils = require "utils"
log = utils.log
col = utils.colorize

local transpiler = require "transpiler"
rule = transpiler.rule
basic = transpiler.basicActions
sv = transpiler.semanticValue

local testText = [[
rule them all
match cannot work outside transpiler
token and nichole
concat with spaces
csv with commae
subs cannot work outside transpiler
forward and for honor
default rule should warn
]]


-- test the naked parser

print(col("\ntesting the naked parser\n", "brightgreen"))
local pp = pegparser{
	grammar = [[
		list <- "\n"* item*
		item <- (rule / match / token / concat / csv / subs / forward / default) ("\n"+ / !.)
		rule <- "rule" (" " word)*
		match <- "match" (" " word)*
		token <- "token" <(" " word)*>
		concat <- "concat" (" " word)*
		csv <- "csv" (" " word)*
		subs <- "subs" (" " word)*
		forward <- "forward" (" " word)*
		default <- "default" (" " word)*
		word <- [a-zA-Z0-9]+
	]],
	actions = {
		list = function(arg) return 123 end,
		item = function(arg) log(arg.values) return nil end,
		rule = basic.rule,
		match = basic.match,
		token = basic.token,
		concat = basic.concat,
		csv = basic.csv,
		subs = basic.subs,
		forward = basic.forward,
		word = basic.rule
	},
	default = function(arg)
		print("Warning: rule '" .. arg.rule .. "' has no action")
		return nil
	end
}


print(col("\nreturned values of the basic rules:\n", "brightgreen"))

local result = pp:parse(testText)

print(col("\nresult:\n", "brightgreen"))

log(result)


-- test rule conversion
print(col("\ntesting rule conversion\n", "brightgreen"))
transpiler.clear()
rule([[ rulename <- <token> $capture(stuff) $reference ignored {considered} ]], "cucumber")
print(transpiler.grammar())


-- test transpiler
print(col("\ntesting transpiler module\n", "brightgreen"))
transpiler.clear()


rule([[ list <- "\n"* {item}* ]], "match=<<<{match}>>> val1={1} val2={2} val3={3} val100={100}")
rule([[ item <- ({rule} / {match} / {token} / {concat} / {csv} / {subs} / {forward} / {default}) ("\n"+ / !.) ]],
	function(arg)
		--log(arg.values)
		local result = sv.new(arg)
		result.str = "(" .. arg.rule .. ")"
		return result
	end
)
rule([[ rule <- "rule" (" " word)* ]], basic.rule)
rule([[ match <- "match" (" " word)* ]], basic.match)
rule([[ token <- "token" <(" " word)*> ]], basic.token)
rule([[ concat <- "concat" (" " {word})* ]], basic.concat)
rule([[ csv <- "csv" (" " {word})* ]], basic.csv)
rule([[ subs <- "subs" (" " {word})* ]], basic.subs)
rule([[ forward <- "forward" (" " word)* ]], basic.forward)
rule([[ default <- "default" (" " word)* ]])
rule([[ word <- [a-zA-Z0-9]+ ]], basic.rule)

print(col("\nresulting grammar:\n", "brightgreen"))
print(transpiler.grammar())

print(col("\ntranspilation\n", "brightgreen"))
print(transpiler.transpile(testText).str)
