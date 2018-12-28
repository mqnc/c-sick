
-- the module that will be exported
local transpiler = {}

-- the private lists of rules and actions
local ruleList = {}
local actionList = {}
local parsingText = ""

-- swipe clean
transpiler.clear = function()
	ruleList = {}
	actionList = {}
	parsingText = ""
end

-- return the matched text from a table containing a pos and len reference to the parsing text
transpiler.match = function(arg)
	return parsingText:sub(arg.pos, arg.pos + arg.len - 1)
end

-- set of standard reduction actions
transpiler.basicActions = {

	-- output the name of the rule that was reduced
	rule = function(arg)
		return {result.rule}
	end,

	-- output the matched text
	--[[match = function(arg)
		return {transpiler.match(arg)}
	end,]]
	match = "\\match",

	-- output the first captured token (raw text)
	token = function(arg)
		return {arg.tokens[1]}
	end,

	-- concat all captured semantic values
	concat_ = function(arg)
		local result = ""
		local sep = ""
		for i = 1, #arg.values do
			result = result .. sep .. arg.values[i][1]
			--sep = " " -- see if it works without spaces
		end
		return {result}
	end,
	concat = "\\concat",

	-- concat all captured semantic values with a comma in between
	csv = function(arg)
		local result = ""
		local sep = ""
		for i = 1, #arg.values do
			result = result .. sep .. arg.values[i][1]
			sep = ", "
		end
		return {result}
	end,

	-- just forward all parameters
	forward = function(arg)
		local resultTbl = {""}
		resultTbl.values = arg.values
		for i, v in ipairs(arg.values) do
			resultTbl[1] = resultTbl[1] .. v[1] .. " "
		end
		return resultTbl
	end
}

-- create a parsing rule
transpiler.rule = function(definition, action, comment)

	-- extract name of the rule
	name = definition:match("[%w_]+")

	-- if the rule does not exist yet, associate a new index with it
	if ruleList[name] == nil then
		ruleList[#ruleList+1] = name
	else
		print('warning: rule "' .. name .. '" will be overwritten')
	end

	-- create action
	if type(action) == "function" then

		-- just register the provided action
		actionList[name] = action
		local found = false
		for fname, f in pairs(transpiler.basicActions) do
			if action == f then
				definition = definition .. "  # -> " .. fname
				if comment ~= nil then
					definition = definition .. "; " .. comment
				end
				found = true
			end
		end
		if not found then
			if comment ~= nil then
				definition = definition .. "  # -> " .. comment
			else
				definition = definition .. "  # -> special action"
			end
		end

	elseif type(action) == "string" then

		-- return a string but:
 			-- replace "{#}" with the #-th semantic value
			-- replace "{match}" with the complete match

		definition = definition .. "  # -> '" .. action:gsub("\n", "\\n") .. "'"
		if comment ~= nil then
			definition = definition .. "; " .. comment
		end

		if action=="\\match" or action=="\\concat" then
			actionList[name] = action
		else
			actionList[name] = function(arg)
				result = action
				for i, v in ipairs(arg.values) do
					result = result:gsub("{" .. i .. "}", v[1])
				end
				result = result:gsub("{match}", transpiler.match(arg))
				return {result}
			end
		end
	else

		definition = definition .. "  # (no action)"

		actionList[name] = function(arg)
			return {"UNDEFINED"}
		end
	end

	-- create/update rule
	ruleList[name] = definition
end


-- compose grammar from all registered rules
transpiler.grammar = function()
	local result = ""
	for i, r in ipairs(ruleList) do
		result = result .. ruleList[r] .. "\n"
	end
	return result
end


-- do transpilation
transpiler.transpile = function(code)

	parsingText = code

	local pp = pegparser{
		grammar = transpiler.grammar(),
		actions = actionList,
		default = function(arg) return nil end
	}

	return pp:parse(code)

end

return transpiler
