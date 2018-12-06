
local utils = {}

-- path separator
utils.sep = package.config:sub(1,1)

utils.dump = function(obj)
	print(stringify(obj))
end

utils.readAll = function(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

utils.writeToFile = function(fname, text)
	fout = io.open(fname, "w")
	io.output(fout)
	io.write(text)
	io.close(fout)
end

return utils
