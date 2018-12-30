
local utils = require "utils"
local log = utils.log
local col = utils.colorize

local transpiler = require "transpiler"
local rule = transpiler.rule
local basic = transpiler.basicActions
local match = transpiler.match

local indent = 0



rule([[ Code <- (Comment / StringLiteral / IndentInc / IndentDec / NewLine / WhiteSpace / Anything)* ]], basic.concat)
rule([[ Comment <- LineEndComment / MultiLineComment ]], basic.match)
rule([[ LineEndComment <- '//' (!NewLine .)* ]])
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ StringLiteral <- CharConstant / SimpleString / MultiLineString ]], basic.match)
rule([[ CharConstant <- '\'' (('\\' .) / .) '\'' ]])
rule([[ SimpleString <- '"' (('\\' .) / (!'"' .))* '"' ]])
rule([[ MultiLineString <- 'R"' $delim<[a-zA-Z_0-9]*> '(' (!(')' $delim '"') .)* ')' $delim '"' ]])
rule([[ Anything <- . ]], basic.match)

rule([[ WhiteSpace <- [ \t]+ ]], " " )
rule([[ NewLine <- ~WhiteSpace* (('\r\n' / '\n' / !.) ~WhiteSpace*)+ IndentDec?]],
	function(arg)
		local result = "\n" .. string.rep("\t", indent)
		if arg.values[1] then
			result = result .. arg.values[1][1]
		end
		return {result}
	end
)
rule([[ IndentInc <- "(" / "{" ]],
	function(arg)
		indent = indent + 1
		return {match(arg)}
	end
)
rule([[ IndentDec <- ")" / "}" ]],
	function(arg)
		indent = indent - 1
		if indent<0 then indent=0 end
		return {match(arg)}
	end
)

return function(uglycode)
	indent = 0
	return transpiler.transpile(uglycode)[1]
end
