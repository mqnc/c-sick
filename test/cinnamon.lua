
utils = require "utils"
transpiler = require "transpiler"
rule = transpiler.rule
basic = transpiler.basicActions


keywords = {}
identifiers = {}
globalStatements = {}
localStatements = {}

sep = package.config:sub(1,1)
dofile("language" .. sep .. "core.lua")



table.insert(globalStatements, "{SyntaxError}")
table.insert(localStatements, "{SyntaxError}")
rule([[ SyntaxError <- (!nl .)* nl ]],  string.char(27) .. '[91m' .. "{match}" .. string.char(27) .. '[39m\n' )

if #keywords == 0 then
    rule( "Keyword <- !. .", "")
else
    rule( "Keyword <- (" .. table.concat(keywords, " / ") .. " ) NameEnd", basic.subs)
end
rule( "Identifier <- !Keyword (" .. table.concat(identifiers, " / ") .. " )", basic.subs)
rule( "GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.subs)
rule( "LocalStatement <- " .. table.concat(localStatements, " / "), basic.subs)


input = utils.readAll("snippets/core.mon")

print(transpiler.grammar())
utils.writeToFile("testgrammar.peg", transpiler.grammar())

debug = false
print(transpiler.transpile(input, debug))
