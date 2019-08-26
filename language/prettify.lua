
local scriptPath = string.gsub((...), "prettify$", "")

local utils = require (scriptPath .. "utils")
local log = utils.log
local col = utils.colorize

local transpiler = require (scriptPath .. "transpiler")
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
	function(sv, info)
		local result = "\n" .. string.rep("\t", indent)
		if sv[1] then
			result = result .. sv[1].txt
		end
		return {txt=result}
	end
)
rule([[ IndentInc <- "(" / "{" ]],
	function(sv, info)
		indent = indent + 1
		return {txt=match(info)}
	end
)
rule([[ IndentDec <- ')' / '}' ]],
	function(sv, info)
		indent = indent - 1
		if indent<0 then indent=0 end
		if match(info) == "}" then
			return {txt="}"}
		else
			return {txt=")"}
		end
	end
)

return function(uglycode)
	indent = 0
	return transpiler.transpile(uglycode).txt
end
