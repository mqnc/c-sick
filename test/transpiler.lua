
local transpiler = {}

local ruleList = {}
local actionList = {}

transpiler.clear = function()
	ruleList = {}
	actionList = {}
end



transpiler.basicActions = {

	-- return the name of the rule that was reduced
	rule = function(params)
		return params.rule
	end,

	-- return the matched text
	match = function(params)
		return params.matched
	end,

	-- return the first captured token (raw text)
	token = function(params)
 		return params.tokens[1]
	end,

	-- concat all captured semantic values with a space in between
	concat = function(params)
		local output = ""
		for i = 1, #params.values do
			output = output .. params.values[i].output .. " "
		end
		return output
	end,

	-- return the matched text but substitute all semantic values at their positions
	subs = function(params)

		local output = params.matched
		for i = #params.values, 1, -1 do
			local offset = params.values[i].position - params.position
			output = output:sub(1, offset) .. stringify(params.values[i].output) .. output:sub(offset + params.values[i].length + 1)
		end
		return output
	end,

	-- just forward all parameters
	forward = function(params)
		return params
	end
}



-- extended peg grammar for rule transformation
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
		Definition = function(params)
			return {
				name = params.values[2].output,
				pattern = params.values[5].output
			}
		end,
		IndexedId = function(params)
			return params.values[1].output .. params.values[2].output
		end,
		IgnoredId = function(params)
			return '~' .. params.values[1].output .. params.values[2].output
		end
	},
	default = transpiler.basicActions.subs,
	packrat = true,
	debuglog = false
}



transpiler.rule = function(entry, action)
	--print("parsing " .. entry)

	local definition = ruleParser:parse(entry).output

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
				found = true
			end
		end
		if not found then
			definition.pattern = definition.pattern .. "  # -> special action"
		end

	elseif type(action) == "string" then

		-- return a string but:
 			-- replace "{#}" with the #-th semantic value
			-- replace "{match}" with the complete match

		definition.pattern = definition.pattern .. "  # -> '" .. action:gsub("\n", "\\n") .. "'"

		actionList[definition.name] = function(params)
			local output = action
			for i, v in ipairs(params.values) do
				output = output:gsub("{" .. i .. "}", v.output)
			end
			output = output:gsub("{match}", params.matched)
			return output
		end

	else

		definition.pattern = definition.pattern .. "  # -> NIL"

	end

	-- create/update rule
	ruleList[definition.name] = definition.pattern
end



transpiler.grammar = function()
	local result = ""
	for i, r in ipairs(ruleList) do
		result = result .. r .. ' <- ' .. ruleList[r] .. "\n"
	end
	return result
end



transpiler.transpile = function(code, debug)

	local transpiler = pegparser{
		grammar = transpiler.grammar(),
		actions = actionList,
		default = function(params)
			--print('warning: rule "' .. params.rule .. '" has no action');
			return 'NIL'
		end,
		packrat = true,
		debuglog = (debug==true)}

	return transpiler:parse(code).output

end

return transpiler
