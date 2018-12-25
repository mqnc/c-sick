
local utils = require "utils"
local log = utils.log
local col = utils.colorize

local transpiler = require "transpiler"
local rule = transpiler.rule
local basic = transpiler.basicActions
local sv = transpiler.semanticValue.new

local indent = 0



rule([[ Code <- ({Comment} / {StringLiteral} / {IndentInc} / {IndentDec} / {nl} / {_} / Anything)* ]], basic.subs)
rule([[ Comment <- <SingleLineComment / MultiLineComment> ]], basic.token)
rule([[ SingleLineComment <- '//' (!nl .)* ]])
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ StringLiteral <- <CharConstant / SimpleString / MultiLineString> ]], basic.token)
rule([[ CharConstant <- '\'' (('\\' .) / .) '\'' ]])
rule([[ SimpleString <- '"' (('\\' .) / (!'"' .))* '"' ]])
rule([[ MultiLineString <- 'R"' $delim<[a-zA-Z_0-9]*> '(' (!(')' $delim '"') .)* ')' $delim '"' ]])
rule([[ Anything <- . ]])

rule([[ _ <- [ \t]+ ]], " " )
rule([[ nl <- _* <(('\r\n' / '\n' / !.) _*)+> {IndentDec}?]],
	function(arg)
		local result = sv(arg)
		result.str = "\n"
		for i=1,indent do
			result.str = result.str .. "\t"
		end
		if arg.values[1] then
			result.str = result.str .. arg.values[1].str
		end
		return result
	end
)
rule([[ IndentInc <- <"(" / "{"> ]],
	function(arg)
		indent = indent + 1
		return basic.token(arg)
	end
)
rule([[ IndentDec <- <")" / "}"> ]],
	function(arg)
		indent = indent - 1
		if indent<0 then indent=0 end
		return basic.token(arg)
	end
)

return function(uglycode)
	indent = 0
	return transpiler.transpile(uglycode).str
end
