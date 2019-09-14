
-- rule([[ FieldDeclaration <- ConstSpecifier _ FieldSpecifiers _ Identifier _ AssignOperator _ Assigned _ Terminal ]], fieldGenerator )
function fieldGenerator(sv, info)
		-- pun intended

	local const = sv[1]

	local privacy = 0 -- 0=pbulic, 1=protected, 2=private
	local specs = sv[3]
	local static = false
	local id = sv[5]
	local assigned = sv[9]

	if specs.choice == "list" then
		for i=1, #specs do
			if specs[i].txt == "protected" then
				privacy = 1
			elseif specs[i].txt == "private" then
				privacy = 2
			elseif specs[i].txt == "static" then
				static = true
			end
		end
	end

	local result = {}

	if privacy == 0 then
		table.insert(result, "public: ")
	elseif privacy == 1 then
		table.insert(result, "protected: ")
	else
		table.insert(result, "private: ")
	end

	table.insert(result, const.txt .. " ")

	if static then
		-- ISO C++ forbids in-class initialization of non-const static member
		--table.insert(result, "static ")
	end

	table.insert(result, "remRefDecltype(" .. assigned.txt .. ") "
			.. id.txt .. " = " .. assigned.txt .. ";\n")

	return {txt=table.concat(result)}
end
