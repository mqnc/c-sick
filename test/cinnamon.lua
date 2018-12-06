
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




rule( "Keyword <- (" .. table.concat(keywords, " / ") .. " ) NameEnd", basic.subs)
rule( "Identifier <- !Keyword (" .. table.concat(identifiers, " / ") .. " )", basic.subs)
rule( "GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.subs)
rule( "LocalStatement <- " .. table.concat(localStatements, " / "), basic.subs)


input = utils.readAll("code.mon")

print(transpiler.grammar())
debug = false
print(transpiler.transpile(input, debug))
