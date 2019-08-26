
function functionGenerator(sv, info)
	local specs = sv[3]
	local name = sv[5]
	local params = sv[7]
	local retn = sv[9]
	local body = sv[12]
	local lastretn = sv[13]

	--dump({specs=specs, name=name, params=params, retn=retn, body=body, lastretn=lastretn})

	local result = ""

	----------------------
	-- check specifiers --
	----------------------
	local inline = false
	local kwargs = false
	if specs.choice == "list" then
		for i=1, #specs do
				if specs[i].txt == "inline" then
				inline = true
			elseif specs[i].txt == "kwargs" then
				kwargs = true
			end
		end
	end

	------------------------
	-- scan for templates --
	------------------------

	local itparam = 0
	local templates = {}
	for i=1, #params do
		if params[i].decl.choice == "templated" then
			itparam = itparam+1
			table.insert(templates, "typename T" .. itparam)
		end
	end
	if #templates > 0 then
		result = result .. "template<" ..table.concat(templates, ", ") .. ">\n"
	end

	------------------------
	-- check return types --
	------------------------
	if inline then
		result = result .. "inline "
	end

	local arrowReturn = false
	if retn.choice == "explicit" then
		-- we will use the -> notation
		result = result .. "auto "
		arrowReturn = true
	else
		if lastretn.retn.choice == nil or lastretn.retn.choice == "void" then
			result = result .. "void "
		else
			result = result .. "auto " -- return type deduction
		end
	end

	-------------------
	-- function name --
	-------------------
	result = result .. name.txt

	----------------
	-- parameters --
	----------------
	result = result .. "("
	itparam = 0 -- template parameter counter
	for i=1, #params do
		if i>1 then result = result .. ", " end

		if params[i].specs.choice == "constant" then
			result = result .. "const "
		end

		if params[i].decl.choice == "templated" then
			itparam = itparam+1
			result = result .. "T" .. itparam .. " " .. params[i].name.txt
		elseif params[i].decl.choice == "required" then
			result = result .. params[i].decl.txt .. " " .. params[i].name.txt
		elseif params[i].decl.choice == "default" then
			result = result .. "decltype(" .. params[i].decl.txt .. ") " .. params[i].name.txt .. " = " .. params[i].decl.txt
		end
	end
	result = result .. ")"

	------------------
	-- arrow return --
	------------------
	if arrowReturn then
		result = result .. " -> "

		if retn.subchoice == "single" then
			result = result .. retn.txt

		elseif retn.subchoice == "tuple" then
			result = result .. "std::tuple<"
			local retnfields = {}
			for i=1, #retn do
				table.insert(retnfields, retn[i].spec .. " " .. retn[i].name)
			end
			result = result .. table.concat(retnfields, ", ") .. ">"

		elseif retn.subchoice == "struct" then

			-- struct NAME{
			local structName = mark .. name.txt .. "_result"
			local struct = "struct " .. structName .. "{\n"

			-- list members
			local fields = {}
			for i=1, #retn do
				table.insert(fields, retn[i].spec .. " " .. retn[i].type .. " " .. retn[i].name .. ";\n")
			end
			struct = struct .. table.concat(fields)

			-- construct tuple to construct from / cast to
			local typelist = {}
			for i=1, #retn do
				table.insert(typelist, retn[i].spec .. " " .. retn[i].type)
			end
			local tupleType = "std::tuple<" .. table.concat(typelist, ", ") .. ">"

			-- constructor from tuple
			struct = struct .. structName .. "(" .. tupleType .. " " .. mark .. "tup):\n"
			local coloninits = {}
			for i=1, #retn do
				table.insert(coloninits, retn[i].name .. "(std::get<" .. i-1 .. ">(" .. mark .. "tup))")
			end
			struct = struct .. table.concat(coloninits, ",\n") .. "{}\n"

			-- cast to tuple operator
			struct = struct .. "operator " .. tupleType .. "(){\nreturn {"
			local bracelist = {}
			for i=1, #retn do
				table.insert(bracelist, retn[i].name)
			end
			struct = struct .. table.concat(bracelist, ", ") .. "};\n}\n};\n"

			result = struct .. result .. structName
		end
	end

	----------
	-- body --
	----------
	result = result .. "\n{\n" .. body.txt .. "\n}\n"

	return {txt=result}
end
