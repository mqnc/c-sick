
local utils = require "utils"
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

sep = package.config:sub(1,1) -- platform specific path seperator
dofile("language" .. sep .. "core.lua")
dofile("language" .. sep .. "rawcpp.lua")
dofile("language" .. sep .. "loop.lua")
dofile("language" .. sep .. "function.lua")

table.insert(globalStatements, "{LocalStatement}") -- TODO: THIS IS FOR DEBUGGING REASONS, REMOVE THIS!!!

table.insert(globalStatements, "{SyntaxError}")
table.insert(localStatements, "{SyntaxError}")
rule([[ SyntaxError <- (!nl .)* nl ]],  col("{match}", "brightred") )

if #keywords == 0 then
    rule( "Keyword <- !. .", "")
else
    rule( "Keyword <- (" .. table.concat(keywords, " / ") .. " ) NameEnd", basic.subs)
end
rule( "Identifier <- !Keyword ( " .. table.concat(identifiers, " / ") .. " )", basic.subs)
rule( "GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.subs)
rule( "LocalStatement <- " .. table.concat(localStatements, " / "), basic.subs)


input = utils.readAll("snippets/function.mon")

print(transpiler.grammar())
utils.writeToFile("testgrammar.peg", transpiler.grammar())

print(transpiler.transpile(input))
