
--[[
Todo:

replace
object.element
by
ELEMENT = 2
object[ELEMENT]
(speedtest before)

speedtest compare:
f(a,b) and f{a,b}
and maybe do

action = function(info, values, tokens)
	info[STRING] = values[1][STRING]
	return info
end

create a keys(tbl) and a vals(tbl) iterator

use stringstream

somehow make a concat that concats all tbl[i].str

also create a list for expressions and atomics

maybe generate a table instead of a string and do a huge concat for all the source code in the end
]]

print(_VERSION)

local utils = require "utils"
ss = utils.stringstream
append = utils.append
remove = utils.remove
join = utils.join
log = utils.log
col = utils.colorize

local transpiler = require "transpiler"
rule = transpiler.rule
basic = transpiler.basicActions
sv = transpiler.semanticValue.new


keywords = {}
identifiers = {}
globalStatements = {}
localStatements = {}

local sep = package.config:sub(1,1) -- platform specific path seperator
dofile("language" .. sep .. "core.lua")
dofile("language" .. sep .. "literal.lua")
dofile("language" .. sep .. "rawcpp.lua")
dofile("language" .. sep .. "branch.lua")
dofile("language" .. sep .. "loop.lua")
dofile("language" .. sep .. "function.lua")
dofile("language" .. sep .. "expression.lua")

table.insert(globalStatements, "{LocalStatement}") -- TODO: THIS IS FOR DEBUGGING REASONS, REMOVE THIS!!!

table.insert(globalStatements, "{SyntaxError}")
table.insert(localStatements, "{SyntaxError}")
--rule([[ SyntaxError <- (!nl .)* nl ]],  col("{match}", "brightred") )
rule([[ SyntaxError <- (!nl .)* nl ]],  "//!\\\\{match}" )

if #keywords == 0 then
    rule( "Keyword <- !. .", "")
else
    rule( "Keyword <- (" .. table.concat(keywords, " / ") .. " ) NameEnd", basic.subs)
end
rule( "Identifier <- !Keyword ( " .. table.concat(identifiers, " / ") .. " )", basic.subs)
rule( "GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.subs)
rule( "LocalStatement <- " .. table.concat(localStatements, " / "), basic.subs)


local input = utils.readAll("snippets/all.mon")

--print(transpiler.grammar())
--utils.writeToFile("testgrammar.peg", transpiler.grammar())

local t0 = os.clock()

local result = transpiler.transpile(input).str

print(os.clock() - t0)

transpiler.clear()
local prettify = require "prettify"

print(prettify(result))
