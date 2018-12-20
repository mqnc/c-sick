
utils = require "utils"
transpiler = require "transpiler"
log = transpiler.log
rule = transpiler.rule
basic = transpiler.basicActions
sv = transpiler.semanticValue
col = transpiler.colorize

keywords = {}
identifiers = {}
globalStatements = {}
localStatements = {}

sep = package.config:sub(1,1) -- platform specific path seperator
dofile("language" .. sep .. "core.lua")
--dofile("language" .. sep .. "rawcpp.lua")
dofile("language" .. sep .. "loop.lua")

table.insert(globalStatements, "{LocalStatement}") -- TODO: THIS IS FOR DEBUGGING REASONS, REMOVE THIS!!!

table.insert(globalStatements, "{SyntaxError}")
table.insert(localStatements, "{SyntaxError}")
rule([[ SyntaxError <- (!nl .)* nl ]],  string.char(27) .. '[91m' .. "{match}" .. string.char(27) .. '[39m\n' )

if #keywords == 0 then
    rule( "Keyword <- !. .", "")
else
    rule( "Keyword <- (" .. table.concat(keywords, " / ") .. " ) NameEnd", basic.subs)
end
rule( "Identifier <- !Keyword ( " .. table.concat(identifiers, " / ") .. " )", basic.subs)
rule( "GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.subs)
rule( "LocalStatement <- " .. table.concat(localStatements, " / "), basic.subs)


input = utils.readAll("snippets/loop.mon")

print(transpiler.grammar())
utils.writeToFile("testgrammar.peg", transpiler.grammar())

debug = false
print(transpiler.transpile(input, debug))
