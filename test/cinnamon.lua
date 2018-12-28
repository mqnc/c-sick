
--[[
Todo:

create a keys(tbl) and a vals(tbl) iterator

somehow make a concat that concats all tbl[i].str

maybe generate a table instead of a string and do a huge concat for all the source code in the end

redo the match function

work more with position inside the original text instead of strings

implement the standard rules in cpp
]]

print(_VERSION)

local utils = require "utils"
ss = utils.stringstream
append = utils.append
join = utils.join
log = utils.log
col = utils.colorize

local transpiler = require "transpiler"
rule = transpiler.rule
basic = transpiler.basicActions

keywords = {}
identifiers = {}
globalStatements = {}
localStatements = {}

local sep = utils.pathSep -- platform specific path seperator
dofile("language" .. sep .. "core.lua")
--[[dofile("language" .. sep .. "literal.lua")
dofile("language" .. sep .. "rawcpp.lua")
dofile("language" .. sep .. "branch.lua")
dofile("language" .. sep .. "loop.lua")
dofile("language" .. sep .. "function.lua")]]
dofile("language" .. sep .. "expression.lua")

print(col("REMOVE LOCALSTATEMENT = GLOBALSTATEMENT", "brightred"))
table.insert(globalStatements, "LocalStatement") -- TODO: THIS IS FOR DEBUGGING REASONS, REMOVE THIS!!!

table.insert(globalStatements, "SyntaxError")
table.insert(localStatements, "SyntaxError")


if #keywords == 0 then
    rule( "Keyword <- !. .", "")
else
    rule( "Keyword <- (" .. table.concat(keywords, " / ") .. " ) NameEnd", basic.concat)
end
rule( "Identifier <- !Keyword ( " .. table.concat(identifiers, " / ") .. " )", basic.concat)
rule( "GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.concat)
rule( "LocalStatement <- " .. table.concat(localStatements, " / "), basic.concat)


local input = string.rep(utils.readAll("snippets/all.mon"),10)

print(transpiler.grammar())
--utils.writeToFile("testgrammar.peg", transpiler.grammar())

local t0 = os.clock()

--local result = join(transpiler.transpile(input)[1])
local result = transpiler.transpile(input)

print(os.clock() - t0)

transpiler.clear()
--local prettify = require "prettify"

--print((result))
