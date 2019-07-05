
print(_VERSION)

local codefile = "snippets/all.mon"

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

-- the language modules add elements to these tables and they will be turned into grammar in the end
keywords = {}
identifiers = {}
globalStatements = {}
localStatements = {}

-- load the language modules
local sep = utils.pathSep -- platform specific path seperator
dofile("languagemodules" .. sep .. "core.lua")
dofile("languagemodules" .. sep .. "literal.lua")
dofile("languagemodules" .. sep .. "rawcpp.lua")
dofile("languagemodules" .. sep .. "branch.lua")
dofile("languagemodules" .. sep .. "loop.lua")
dofile("languagemodules" .. sep .. "function.lua")
dofile("languagemodules" .. sep .. "expression.lua")

-- include grammar elements that have to be tested after everything else
print(col("REMOVE LOCALSTATEMENT = GLOBALSTATEMENT", "brightred"))
table.insert(globalStatements, "LocalStatement") -- TODO: THIS IS FOR DEBUGGING REASONS, REMOVE THIS!!!

-- these elements need to be the last ones that are tested
table.insert(localStatements, "Expression _ Terminal")
table.insert(globalStatements, "SyntaxError")
table.insert(localStatements, "SyntaxError")

-- construct grammar from the tables
if #keywords == 0 then
    rule( "Keyword <- !. .", "")
else
    rule( "Keyword <- (" .. table.concat(keywords, " / ") .. " ) NameEnd", basic.concat)
end
rule( "Identifier <- !Keyword ( " .. table.concat(identifiers, " / ") .. " )", basic.concat)
rule( "GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.concat)
rule( "LocalStatement <- " .. table.concat(localStatements, " / "), basic.concat)

-- repetition for increasing work load to measure performance
local input = string.rep(utils.readAll(codefile), 1)

-- display grammar
print(transpiler.grammar())

-- store grammar
--utils.writeToFile("testgrammar.peg", transpiler.grammar())

-- transpile
local t0 = os.clock()
local result = transpiler.transpile(input)[1]
local t1 = os.clock()

-- prettify
transpiler.clear()
local prettify = require "prettify"

-- display results
print(prettify(result))
print("transpile CPU time: " .. t1-t0 .. "s")
