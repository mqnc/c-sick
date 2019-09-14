
-- rule([[ CtorDeclaration <- CtorKeyword _ MemberSpecifiers _ Parameters _ Terminal Skip Inits CtorBody EndKeyword ]], ctorGenerator )

function ctorGenerator(sv, info)
	local specs = sv[3]
	local params = sv[5]
	local init = sv[9]
	local body = sv[10]
	local class = classStack[#classStack].name

	result = ""

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

	result = result .. class

	----------------
	-- parameters --
	----------------
	result = result .. "("
	itparam = 0 -- template parameter counter
	for i=1, #params do
		if i>1 then result = result .. ", " end

		ref = ""

		if params[i].specs.choice == "constant" then
			result = result .. "const "
			--ref = "&" -- const params are automatically handed by reference -- caused issues, see the thoughts.txt
		end

		if params[i].decl.choice == "templated" then
			itparam = itparam+1
			result = result .. "T" .. itparam .. ref .. " " .. params[i].name.txt
		elseif params[i].decl.choice == "required" then
			result = result .. params[i].decl.txt .. ref .. " " .. params[i].name.txt
		elseif params[i].decl.choice == "default" then
			result = result .. "remRefDecltype(" .. params[i].decl.txt .. ") " .. ref .. params[i].name.txt .. " = " .. params[i].decl.txt
		end
	end
	result = result .. ")"

	-----------------------
	-- colon initializer --
	-----------------------

	if init.choice == "init" then
		result = result .. ":" .. init.txt
	elseif init.choice == "delegate" then
		result = result .. ":" .. init.txt
	end

	----------
	-- body --
	----------

	result = result .. "\n{\n" .. body.txt .. "\n}\n"

	return {txt = result}

end
