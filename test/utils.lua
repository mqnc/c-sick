
local utils = {}

-- path separator
utils.sep = package.config:sub(1,1)

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


local ansiColors = true
-- enable/disable colored output
utils.ansiColors = function(enable)
	if type(enable) == "boolean" then
		ansiColors = enable
	end
end

-- ansi color codes
local ESC = string.char(27)

local palette = {
	default = ESC .. "[0m",
	black = ESC .. "[30m",
	red = ESC .. "[31m",
	green = ESC .. "[32m",
	yellow = ESC .. "[33m",
	blue = ESC .. "[34m",
	magenta = ESC .. "[35m",
	cyan = ESC .. "[36m",
	white = ESC .. "[37m",
	brightblack = ESC .. "[90m",
	brightred = ESC .. "[91m",
	brightgreen = ESC .. "[92m",
	brightyellow = ESC .. "[93m",
	brightblue = ESC .. "[94m",
	brightmagenta = ESC .. "[95m",
	brightcyan = ESC .. "[96m",
	brightwhite = ESC .. "[97m"
}

local col = function(text, color)
	if not ansiColors then
		return text
	end
	return palette[color] .. text .. palette["default"]
end

utils.colorize = col -- make accessible

-- turn something into string, recursively expand tables
utils.stringify = function(obj, indent)
	if nil == indent then
		indent = ""
	end
	if type(obj) == "string" then
		return '"' .. obj .. '"'
	elseif type(obj) == "table" then
		if next(obj) == nil then
			return col("{}", "brightcyan")
		end
		local res = {}
		for k, v in pairs(obj) do
			local key = k
			if type(k) ~= "string" then
				key = "[" .. tostring(k) .. "]"
			end
			res[1 + #res] = indent .. "\t" .. col(key, "brightyellow") .. col(" = ", "brightcyan") .. utils.stringify(v, "\t" .. indent)
		end
		return "\n" .. indent .. col("{", "brightcyan") .. "\n" .. table.concat(res, col(",\n", "brightcyan")) .. "\n" .. indent .. col("}", "brightcyan")
	elseif type(obj) == "function" then
		return tostring(obj) .. col(" -> ", "brightcyan") .. tostring(obj())
	else
		return tostring(obj)
	end
end

-- display something, recursively expand tables
utils.log = function(obj)
	print(utils.stringify(obj))
end

return utils
