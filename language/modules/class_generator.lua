


-- rule([[ ClassDeclaration <- ClassKeyword _ ParametrizedClassName _ OptionalInheritance _ SilentTerminal ClassBody EndClassKeyword ]], classGenerator )
function classGenerator(sv, info)

	local paramdname = sv[3]
	local inherit = sv[5]
	local body = sv[8]

	local result = ""

	if #paramdname == 2 then
		local temps = {}
		for i=1, #paramdname[2] do
			table.insert(temps, "typename " .. paramdname[2][i].txt)
		end
		result = result .. "template<" .. table.concat(temps, ", ") .. ">\n"
	end

	result = result .. "class " .. paramdname[1].txt

	if inherit.choice == "inherit" then
		result = result .. ":" .. inherit.txt
	end

	result = result .. "\n{\n" .. body.txt .. "\n};\n"

	return {txt=result}
end
