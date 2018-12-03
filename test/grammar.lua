

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
	return nil
end

actions.rule = function(params)
	return {position = params.position, length = params.length, insert = params.rule}
end

actions.match = function(params)
	return {position = params.position, length = params.length, insert = params.matched}
end

actions.subs = function(params)
	local position = params.position
	local length = params.length
	local insert = params.matched

	for i = #params.values, 1, -1 do
		insert =
			insert:sub(1, params.values[i].position-position) .. 
			params.values[i].insert .. 
			insert:sub(params.values[i].position-position + params.values[i].length + 1)
	end

	return {position = position, length = length, insert = insert}
end

actions.ast = function(params)
	return params
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
			local insert = ""
			if #params.values == 3 then -- action forwarding
				actions[params.values[1].insert] = actions[params.values[2].insert]
				insert = params.values[1].insert .. ' <- ' .. params.values[3].insert .. "\n"
			else
				insert = params.values[1].insert .. ' <- ' .. params.values[2].insert .. "\n"
			end
			return {position = params.position, length = params.length, insert = insert} 
		end
	},
	default = actions.match,
	packrat = true,
	debuglog = false}

grammar = reductionExtractor:parse(grammar).insert

pp = pegparser{
	grammar = grammar,
	actions = actions,
	default = actions.subs,
	packrat = packrat,
	debuglog = debuglog}

output = pp:parse(input).insert

print(output)

writeToFile("test/snippet.lzz", output)
