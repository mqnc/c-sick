
print(_VERSION)

local scriptPath = string.gsub(arg[0], "cinnamon.lua$", "")

local inputfile = arg[1]
local outputfile = arg[2]

local utils = require (scriptPath .. "utils")
log = utils.log
col = utils.colorize

local transpiler = require (scriptPath .. "transpiler")
rule = transpiler.rule
basic = transpiler.basicActions

-- the language modules add elements to these tables and they will be turned into grammar in the end
keywords = {}
literals = {}
globalStatements = {}
localStatements = {}

-- load the language modules
local sep = utils.pathSep -- platform specific path seperator
dofile(scriptPath .. "modules" .. sep .. "core.lua")
dofile(scriptPath .. "modules" .. sep .. "literal.lua")
dofile(scriptPath .. "modules" .. sep .. "expression.lua")
dofile(scriptPath .. "modules" .. sep .. "tuple.lua")
dofile(scriptPath .. "modules" .. sep .. "declaration.lua")
dofile(scriptPath .. "modules" .. sep .. "function.lua")

--print(col("REMOVE LOCALSTATEMENT = GLOBALSTATEMENT", "brightred"))
--table.insert(globalStatements, "LocalStatement") -- TODO: THIS IS FOR DEBUGGING REASONS, REMOVE THIS!!!

-- these elements need to be the last ones that are tested
table.insert(localStatements, "Expression _ Terminal")
table.insert(globalStatements, "SyntaxError")
table.insert(localStatements, "SyntaxError")

-- construct grammar from the tables
if #keywords == 0 then
    rule( " Keyword <- !. .", "")
else
    rule( " Keyword <- (" .. table.concat(keywords, " / ") .. " ) WordEnd", basic.concat)
end
if #literals == 0 then
    rule( " Literal <- !. .", "")
else
    rule( " Literal <- (" .. table.concat(literals, " / ") .. " ) WordEnd", basic.concat)
end
rule( " GlobalStatement <- " .. table.concat(globalStatements, " / "), basic.concat)
rule( " LocalStatement <- " .. table.concat(localStatements, " / "), basic.concat)

if inputfile == nil then

	-- display grammar
	print(transpiler.grammar())

	-- store grammar
	--utils.writeToFile("testgrammar.peg", transpiler.grammar())

else
	local input = string.rep(utils.readAll(inputfile), 1)

	-- transpile
	local t0 = os.clock()
	local result = transpiler.transpile(input)[1]
	local t1 = os.clock()

	-- prettify
	transpiler.clear()
	local prettify = require (scriptPath .. "prettify")
	result = prettify(result)

	-- display results
	print("")
	print(prettify(result))
	print("")
	print("transpile CPU time: " .. t1-t0 .. "s")

	utils.writeToFile(outputfile, result)
end
