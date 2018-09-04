
grammar = {}
actions = {}

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

input = readAll("test/language.txt")

debuglog = true
packrat = not debuglog

function rule(r)
	grammar[1 + #grammar] = r
end

rule([[ Start <- .* ]])
-- grammar development and testing moved to grammar.peg using pegdebug (https://github.com/mqnc/pegdebug)

pp = pegparser{
	grammar = table.concat(grammar, "\n"),
	actions = actions,
	default = htmlwrap,
	packrat = packrat,
	debuglog = debuglog}

function writeToFile(fname, text)
	fout = io.open(fname, "w")
	io.output(fout)
	io.write(text)
	io.close(fout)
end

output = pp:parse(input)

writeToFile("test/output.html", output)
