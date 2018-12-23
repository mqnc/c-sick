
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


-- wrapper class for semantic values
-- the str field should store the resulting output text
-- see standard actions below for examples how to use
transpiler.semanticValue = {

	mt = {
		__tostring = function(value)
			return value.str
		end
	},

	new = function(arg)
		local value = {}
		setmetatable(value, transpiler.semanticValue.mt)
		value.pos = arg.position
		value.len = arg.length
		value.rule = arg.rule
		value.match = function()
			return parsingText:sub(arg.position, arg.position + arg.length - 1)
		end
		value.str = ""
		return value
	end
}

-- set of standard reduction actions
transpiler.basicActions = {

	-- output the name of the rule that was reduced
	rule = function(arg)
		local result = transpiler.semanticValue.new(arg)
		result.str = result.rule
		return result
	end,

	-- output the matched text
	match = function(arg)
		local result = transpiler.semanticValue.new(arg)
		result.str = result.match()
		return result
	end,

	-- output the first captured token (raw text)
	token = function(arg)
		local result = transpiler.semanticValue.new(arg)
		result.str = arg.tokens[1]
		return result
	end,

	-- concat all captured semantic values with a space in between
	concat = function(arg)
		local result = transpiler.semanticValue.new(arg)
		local sep = ""
		for i = 1, #arg.values do
			result.str = result.str .. sep .. arg.values[i].str
			sep = " "
		end
		return result
	end,

	-- concat all captured semantic values with a comma in between
	csv = function(arg)
		local result = transpiler.semanticValue.new(arg)
		local sep = ""
		for i = 1, #arg.values do
			result.str = result.str .. sep .. arg.values[i].str
			sep = ", "
		end
		return result
	end,

	-- output the matched text but substitute all semantic values at their positions
	subs = function(arg)
		local result = transpiler.semanticValue.new(arg)
		result.str = result.match()

		for i = #arg.values, 1, -1 do
			local offset = arg.values[i].pos - arg.position
			result.str = result.str:sub(1, offset) .. arg.values[i].str .. result.str:sub(offset + arg.values[i].len + 1)
		end
		return result
	end,

	-- just forward all parameters
	forward = function(arg)
		local result = transpiler.semanticValue.new(arg)
		result.values = arg.values
		for i, v in ipairs(arg.values) do
			result.str = result.str .. v.str .. " "
		end
		return result
	end
}



-- extended peg grammar for rule transformation
-- turn "rule <- keyword ws {important} ws keyword"
-- into "rule <- ~keyword ~ws important ~ws ~keyword" for peglib
-- so we can highlight considered semantic values instead of highlighting ignored ones
local xpeg = [[
	# Hierarchical syntax
	# Grammar  <- Spacing Definition+ EndOfFile
	Definition <- Spacing Identifier Spacing LEFTARROW Expression
	Expression <- Sequence (SLASH Sequence)*
	Sequence   <- Prefix*
	Prefix     <- (AND / NOT)? Suffix
	Suffix     <- Primary (QUESTION / STAR / PLUS)?
	Primary    <- # Identifier Spacing !LEFTARROW
	              IgnoredId / IndexedId
	              / Token / Capture / Reference
	              / OPEN Expression CLOSE
	              / Literal / Class / DOT

	IgnoredId <- Identifier Spacing !LEFTARROW # id -> ~id
	IndexedId <- '{' Identifier '}' Spacing # {id} -> id
	Token <- TOKENOPEN Expression TOKENCLOSE
	Capture <- Reference Token
	Reference <- REF Identifier Spacing

	# Lexical syntax
	Identifier <- IdentStart IdentCont*
	IdentStart <- [a-zA-Z_]
	IdentCont  <- IdentStart / [0-9]
	Literal    <- ['] (!['] Char)* ['] Spacing
	              / ["] (!["] Char)* ["] Spacing
	Class      <- '[' (!']' Range)* ']' Spacing
	Range      <- Char '-' Char / Char
	Char       <- '\\' [nrt'"\[\]\\]
	              / '\\' [0-2][0-7][0-7]
	              / '\\' [0-7][0-7]?
	              / !'\\' .

	LEFTARROW <- '<-' Spacing
	SLASH     <- '/' Spacing
	AND       <- '&' Spacing
	NOT       <- '!' Spacing
	QUESTION  <- '?' Spacing
	STAR      <- '*' Spacing
	PLUS      <- '+' Spacing
	OPEN      <- '(' Spacing
	CLOSE     <- ')' Spacing
	DOT       <- '.' Spacing
	TOKENOPEN <- '<' Spacing
	TOKENCLOSE<- '>' Spacing
	REF       <- '$' Spacing
	Spacing   <- (Space / Comment)*
	Comment   <- '#' (!EndOfLine .)* EndOfLine
	Space     <- ' ' / '\t' / EndOfLine
	EndOfLine <- '\r\n' / '\n' / '\r'
	EndOfFile <- !.
]]

local ruleParser = pegparser{
	grammar = xpeg,
	actions = {
		Definition = function(arg)
			return {
				name = arg.values[2].str,
				pattern = arg.values[5].str
			}
		end,
		IndexedId = function(arg)
			local result = transpiler.semanticValue.new(arg)
			result.str = arg.values[1].str .. arg.values[2].str
			return result
		end,
		IgnoredId = function(arg)
			local result = transpiler.semanticValue.new(arg)
			result.str = '~' .. arg.values[1].str .. arg.values[2].str
			return result
		end
	},
	default = transpiler.basicActions.subs
}

-- use this function to define parsing rules like this:
-- rule( [[ sum <- {term} _ plus _ {term} ]], basic.subs )
-- use {} to mark semantic values you need
transpiler.rule = function(entry, action, comment)
	parsingText = entry

	local definition = ruleParser:parse(entry)

	if definition == nil then
		error('error while parsing rule "' .. entry .. '"')
		return
	end

	-- if the rule does not exist yet, associate a new index with it
	if ruleList[definition.name] == nil then
		ruleList[#ruleList+1] = definition.name
	else
		print('warning: rule "' .. definition.name .. '" will be overwritten')
	end

	-- create action
	if type(action) == "function" then

		-- just register the provided action
		actionList[definition.name] = action
		local found = false
		for fname, f in pairs(transpiler.basicActions) do
			if action == f then
				definition.pattern = definition.pattern .. "  # -> " .. fname
				if comment ~= nil then
					definition.pattern = definition.pattern .. "; " .. comment
				end
				found = true
			end
		end
		if not found then
			if comment ~= nil then
				definition.pattern = definition.pattern .. "  # -> " .. comment
			else
				definition.pattern = definition.pattern .. "  # -> special action"
			end
		end

	elseif type(action) == "string" then

		-- return a string but:
 			-- replace "{#}" with the #-th semantic value
			-- replace "{match}" with the complete match

		definition.pattern = definition.pattern .. "  # -> '" .. action:gsub("\n", "\\n") .. "'"
		if comment ~= nil then
			definition.pattern = definition.pattern .. "; " .. comment
		end

		actionList[definition.name] = function(arg)
			local result = transpiler.semanticValue.new(arg)
			result.str = action
			for i, v in ipairs(arg.values) do
				result.str = result.str:gsub("{" .. i .. "}", v.str)
			end
			result.str = result.str:gsub("{match}", result.match())
			return result
		end

	else

		definition.pattern = definition.pattern .. "  # (no action)"

		actionList[definition.name] = function(arg)
			local result = transpiler.semanticValue.new(arg)
			result.str = "UNDEFINED"
			return result
		end

	end

	-- create/update rule
	ruleList[definition.name] = definition.pattern
end


-- compose grammar from all registered rules
transpiler.grammar = function()
	local result = ""
	for i, r in ipairs(ruleList) do
		result = result .. r .. ' <- ' .. ruleList[r] .. "\n"
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
