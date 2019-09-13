
-- rule([[ CtorDeclaration <- CtorKeyword _ MemberSpecifiers _ Parameters _ Terminal Skip Inits CtorBody EndKeyword ]], ctorGenerator )

function ctorGenerator(sv, info)
	local specs = sv[3]
	local params = sv[5]
	local init = sv[9]
	local body = sv[10]
	local class = classStack[#classStack].name

	dump(class .. "()")

end
