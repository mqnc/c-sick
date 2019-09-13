
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
transpiler.match = function(info)
	return parsingText:sub(info.pos, info.pos + info.len - 1)
end

-- set of standard reduction actions
transpiler.basicActions = {

	-- output the name of the rule that was reduced
	rule = function(sv, info)
		return {rule=info.rule}
	end,

	-- output the matched text
	match = function(sv, info)
		return {txt=transpiler.match(info)}
	end,

	-- output the first captured token (raw text)
	token = function(sv)
		return {txt=info.tokens[1]}
	end,

	-- concat all txt fields of captured semantic values
	concat = function(sv)
		result = ""
		for i=1, #sv do
			if sv[i].txt == nil then
				result = result .. col("nil", "brightred")
			else
				result = result .. sv[i].txt
			end
		end
		return {txt=result}
		--return {txt=table.concat(fields(sv, "txt"))}
	end,

	-- concat all txt fields of captured semantic values with a comma in between
	csv = function(sv)
		return {txt=table.concat(fields(sv, "txt"), ", ")}
	end,

	-- propagate all parameters
	tree = function(sv, info)
		sv.rule = info.rule
		return sv
	end,

	concat_and_tree = function(sv, info)
		sv.rule = info.rule
		sv.txt = table.concat(fields(sv, "txt"))
		return sv
	end,

	-- forward the specified semantic value
	forward = function(index)
		return function(sv, info)
			return sv[index]
		end
	end,

	-- for a / b / c rules, forwards the sv of the match and a name for it
	choice = function(...)
		local names = {...}
		return function(sv, info)
			local res
			if #sv>0 then
				res = sv[1]
			else
				res = {}
			end
			res.choice = names[info.choice]
			return res
		end
	end,

	-- same as above but the field will be called subchoice so it can be one level deeper without being overwritten
	subchoice = function(...)
		local names = {...}
		return function(sv, info)
			res = sv[1]
			res.subchoice = names[info.choice]
			return res
		end
	end,

	-- return the first and then every fourth value (often needed for lists)
	listFilter = function(sv, info)
		resultTbl = {}
		for i=1, #sv, 4 do
			table.insert(resultTbl, sv[i])
		end
		resultTbl.txt = table.concat(fields(resultTbl, "txt"), ", ")
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
		print(col('warning: rule "' .. name .. '" will be overwritten', 'brightred'))
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

		actionList[name] = function(sv, info)
			result = action
			for i, v in ipairs(sv) do
				if v.txt ~= nil then
					result = result:gsub("{" .. i .. "}", v.txt)
				end
			end
			result = result:gsub("{match}", transpiler.match(info))
			return {txt=result}
		end

	else
		definition = definition .. "  # (no action)"
		actionList[name] = function() return {} end
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
transpiler.transpile = function(code, debug)

	parsingText = code

	if debug then -- wrap all rule calls
		for name,fn in pairs(actionList) do
			actionList[name] = function(sv, info)
				print("Rule " .. name .. ":")
				print("sv=")
				dump(sv)
				print("info=")
				dump(info)
				res = fn(sv, info)
				print("returning:")
				dump(res)
				return res
			end
		end
	end

	local pp = pegparser{
		grammar = transpiler.grammar(),
		actions = actionList,
		default = function(sv, info) return {} end
	}

	return pp:parse(code)
end

return transpiler
