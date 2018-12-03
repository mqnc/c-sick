

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
input = readAll("test/snippet.mon")

actions = {}

debuglog = false
packrat = not debuglog


actions["~"] = function(params)
	return "NIL"
end

actions.rule = function(params)
	return params.rule
end

actions.match = function(params)
	return params.matched
end

actions.token = function(params)
	return params.tokens[1]
end

actions.subs = function(params)
	local output = params.matched
	for i = #params.values, 1, -1 do
		local offset = params.values[i].position - params.position
		output = output:sub(1, offset) .. params.values[i].output .. output:sub(offset + params.values[i].length + 1)
	end
	return output
end

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
	return "!!!>" .. params.matched:sub(1, params.matched:len()-1) .. "<!!!\n"
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



pp = pegparser{
	grammar = grammar,
	actions = actions,
	default = actions.subs,
	packrat = packrat,
	debuglog = debuglog}

output = pp:parse(input).output

print(output)

writeToFile("test/snippet.lzz", output)
