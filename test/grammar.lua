

function dump(obj)
	print(stringify(obj))
end

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

function writeToFile(fname, text)
	fout = io.open(fname, "w")
	io.output(fout)
	io.write(text)
	io.close(fout)
end

grammar = readAll("test/grammar.peg")
input = readAll("test/code.mon")

actions = {}

debuglog = false
packrat = not debuglog


actions["~"] = function(params) return "NIL" end

actions.rule = function(params) return params.rule end

actions.match = function(params) return params.matched end

actions.token = function(params) return params.tokens[1] end

actions.concat = function(params)
	local output = ""
	for i = 1, #params.values do
		output = output .. params.values[i].output .. " "
	end
	return output
end

actions.subs = function(params)
	local output = params.matched
	for i = #params.values, 1, -1 do
		local offset = params.values[i].position - params.position
		output = output:sub(1, offset) .. stringify(params.values[i].output) .. output:sub(offset + params.values[i].length + 1)
	end
	return output
end

actions.forward = function(params) return params end

reductionExtractor = pegparser{
	grammar = [[
		Grammar <- nl* Definition+
		Definition <- Identifier (':' _ Forward)? _ '<-' _ Expression nl
		Forward <- (!(_ '<-') .)*
		Identifier <- [a-zA-Z_] [a-zA-Z0-9_]*
		Expression <- (!nl .)*
		%whitespace <- [ \t]*
		~_ <- [ \t]*
		~nl <- [\r\n]+
	]],
	actions = {
		Grammar = actions.subs,
		Definition = function(params)
			local output = ""
			if #params.values == 3 then -- action forwarding
				actions[params.values[1].output] = actions[params.values[2].output]
				output = params.values[1].output .. ' <- ' .. params.values[3].output .. "\n"
			else
				output = params.values[1].output .. ' <- ' .. params.values[2].output .. "\n"
			end
			return output
		end
	},
	default = actions.match,
	packrat = true,
	debuglog = false}

grammar = reductionExtractor:parse(grammar).output
writeToFile("test/rawgrammar.peg", grammar)


actions.SyntaxError = function(params)
	--return 'static_assert(0, R"ERROR(' .. params.matched:sub(1, params.matched:len()-1) .. ')ERROR");\n'
	--return '!!!>' .. params.matched:sub(1, params.matched:len()-1) .. '<!!!\n'
	return string.char(27) .. '[91m' .. params.matched:sub(1, params.matched:len()-1) .. string.char(27) .. '[39m\n'
end



actions.Specifier = function(params)
	if params.matched == "var" then return "auto" end
	if params.matched == "val" then return "const auto" end
	return params.matched
end

actions.SimpleDeclaration = function(params)
	local i = 1
	local output = ""
	while params.values[i].rule == "Specifier" do
		output = output .. " " .. params.values[i].output
		i = i + 1
	end
	output = output .. " " .. params.values[i].output
	i = i + 1
	if #params.values > i then
		output = output .. " = " .. params.values[i + 1].output
	end
	output = output .. ";\n"
	return output
end



actions.IfPart = function(params)
	return "if( " .. params.values[1].output .. " ){\n" .. params.values[2].output .. "\n}\n"
end

actions.ElseIfPart = function(params)
	return "else if( " .. params.values[1].output .. " ){\n" .. params.values[2].output .. "\n}\n"
end

actions.ElsePart = function(params)
	return "else{\n" .. params.values[1].output .. "\n}\n"
end



actions.SwitchStatement = function(params)
	local output = "switch(" .. params.values[1].output .. "){\n"
	for i = 2, #params.values do
		output = output .. params.values[i].output
	end
	output = output .. "\n}\n"
	return output
end

actions.CaseCondition = function(params)
	local i = 1
	local output = ""
	for i, val in ipairs(params.values) do
		if val.rule == "DefaultKeyword" then
			output = output .. val.output
		else
			output = output .. "case(" .. val.output .. "): "
		end
	end
	return output
end

actions.Case = function(params)
	local output = params.values[1].output .. "\n" .. params.values[2].output .. "\n"
	if #params.values == 2 then -- no fall keyword
		output = output .. "break;\n"
	end
	return output
end

actions.DefaultKeyword = function(params)
	return "default: "
end



actions.WhileStatement = function(params)
	return "while( " .. params.values[1].output .. " ){\n" .. params.values[2].output .. "\n}\n"
end



actions.RepeatStatement = function(params)
	local condition = ""
	if params.values[2].rule == "RepWhileKeyword" then
		condition = "( " .. params.values[3].output .. " )"
	else
		condition = "(!( " .. params.values[3].output .. " ))"
	end
	return "do{\n" .. params.values[1].output .. "\n}\nwhile" .. condition .. "\n"
end



actions.FunctionDeclaration = function(params)

	local name = params.values[1].output
	local specifiers = params.values[2].output
	local parameters = params.values[3].output
	local returns = params.values[4].output
	local body = params.values[5].output

	output = specifiers .. name .. "(" .. parameters .. ")"

	output = output .. "{\n" .. body .. "\n}\n"

	return output
end

actions.ParameterList = function(params)
	local output = ""
	if #params.values >= 1 then
		output = params.values[1].output
	end
	for i = 2, #params.values do
		output = output .. ", " .. params.values[i].output
	end
	return output
end

actions.ParameterAssignOperator = function(params) return " = " end






transpiler = pegparser{
	grammar = grammar,
	actions = actions,
	default = actions.subs,
	packrat = packrat,
	debuglog = debuglog}

output = transpiler:parse(input).output

print(output)

writeToFile("test/code.lzz", output)
