
print(col("TODO: (Thingy / Empty) is a nice way to do optional things instead of Thingy? as it doesnt change the number of sv", "brightred"))

rule([[ ClassDeclaration <- ClassKeyword _ ParametrizedClassName _ OptionalInheritance _ SilentTerminal ClassBody EndClassKeyword ]], classGenerator )

table.insert(globalStatements, "ClassDeclaration")

rule([[ ClassKeyword <- "class" ]], function(sv, info)
	table.insert(classStack, {})
	return {}
end )

rule([[ ParametrizedClassName <- Identifier (_ LTypeBrace _ IdentifierList _ RTypeBrace)* ]], function(sv, info)
	classStack[#classStack].name = sv[1].txt
	return basic.listFilter(sv, info)
end )

rule([[ OptionalInheritance <- Inheritance / NoInheritance ]], basic.choice("inherit", "none"))
rule([[ NoInheritance <- "" ]])
rule([[ Inheritance <- InheritKeyword _ InheritanceList ]], basic.forward(3))
rule([[ InheritKeyword <- "inherits" ]])
rule([[ InheritanceList <- InheritanceListItem (_ Comma _ InheritanceListItem)* ]], basic.listFilter)
rule([[ InheritanceListItem <- AccessMode _ Type ]], basic.concat)
rule([[ AccessMode <- AccessModePrivate / AccessModeProtected / AccessModePublic ]], basic.concat)
rule([[ AccessModePublic <- '' ]], "public ")
rule([[ AccessModePrivate <- LBracket _ "private" _ RBracket ]], "private ")
rule([[ AccessModeProtected <- LBracket _ "protected" _ RBracket ]], "protected ")

rule([[ ClassBody <- Skip (!EndKeyword ClassMemberDeclaration Skip)* ]], basic.concat )

rule([[ ClassMemberDeclaration <- FieldDeclaration / MethodDeclaration / OperatorDeclaration ]], basic.concat )

--rule([[ OperatorDeclaration <- CtorDeclaration / DtorDeclaration / CopyDeclaration / AssignDeclaration / CallDeclaration / AccessDeclaration ]], basic.concat )
rule([[ OperatorDeclaration <- CtorDeclaration / DtorDeclaration ]], basic.concat )

rule([[ MemberSpecifiers <- SomeMemberSpecifiers / NoMemberSpecifiers ]], basic.choice("list", "none") )
rule([[ SomeMemberSpecifiers <- LBracket _ MemberSpecifierList _ RBracket ]], basic.forward(3) )
rule([[ NoMemberSpecifiers <- "" ]])
rule([[ MemberSpecifierList <- MemberSpecifier (_ Comma _ MemberSpecifier)* ]], basic.listFilter)
rule([[ MemberSpecifier <- MemberConst / MemberPrivate / MemberProtected / MemberVirtual / MemberOverride / MemberInline / MemberStatic / MemberKwargs ]], basic.match)

rule([[ MemberConst <- "const" ]])
rule([[ MemberPrivate <- "private" ]])
rule([[ MemberProtected <- "protected" ]])
rule([[ MemberVirtual <- "virtual" ]])
rule([[ MemberOverride <- "override" ]])
rule([[ MemberInline <- "inline" ]])
rule([[ MemberStatic <- "static" ]])
rule([[ MemberKwargs <- "kwargs" ]])

-- METHOD

rule([[ MethodDeclaration <- MethodKeyword _ MemberSpecifiers _ Identifier _ Parameters _ ReturnDeclaration _ Terminal FunctionBody EndFunctionKeyword ]], functionGenerator )

rule([[ MethodKeyword <- 'method' ]], function()
	-- push an empty slot to the function stack for the return statement to store its info in
	table.insert(functionStack, {})
	return {}
end )

--method[const] hustle(x:int, y:int) -> int


-- CONSTRUCTOR

rule([[ CtorDeclaration <- CtorKeyword _ MemberSpecifiers _ Parameters _ Terminal Skip Inits CtorDtorBody EndKeyword ]], ctorDtorGenerator )

rule([[ Inits <- InitList / Delegation / NoInits ]], basic.choice("init", "delegate", "none") )
rule([[ NoInits <- "" ]])

rule([[ CtorKeyword <- "ctor" ]])

rule([[ InitList <- InitKeyword _ Terminal _ FieldAssignmentList _ EndKeyword ]], basic.forward(5))
rule([[ InitKeyword <- "init" ]])
rule([[ FieldAssignmentList <- FieldAssignment _ Terminal (_ FieldAssignment _ Terminal)* ]], basic.listFilter)
rule([[ FieldAssignment <- Identifier _ AssignOperator _ Assigned ]], "{1}{{5}}" )

rule([[ Delegation <- CtorKeyword _ Parameters _ Terminal ]], basic.concat )

rule([[ CtorDtorBody <- Skip (!EndKeyword LocalStatement Skip)* ]], basic.concat )

-- DESTRUCTOR

rule([[ DtorDeclaration <- DtorKeyword _  NoParameters _ MemberSpecifiers _ Terminal CtorDtorBody EndKeyword ]], function(sv, info)

	local specs = sv[3]
	local body = sv[6]

	local privacy = 0
	local virtual = false
	local override = false
	local inline = false
	local class = classStack[#classStack].name

	if specs.choice == "list" then
		for i=1, #specs do
			if     specs[i].txt == "private" then privacy = 2
			elseif specs[i].txt == "protected" then privacy = 1
			elseif specs[i].txt == "inline" then inline = true end
		end
	end

	result = ""

	if privacy == 0 then result = result ..  "public: "
	elseif privacy == 1 then result = result ..  "protected: "
	else result = result ..  "private: " end

	if virtual then result = result .. "virtual " end
	if override then result = result .. "override " end

	result = result .. "~" .. class .. "(){\n" .. body.txt .. "\n}\n"

	return {txt = result}

end )

rule([[ DtorKeyword <- "dtor" ]])

-- FIELD

rule([[ FieldDeclaration <- ConstSpecifier _ FieldSpecifiers _ Identifier _ AssignOperator _ Assigned _ Terminal ]], fieldGenerator )

rule([[ FieldSpecifiers <- SomeFieldSpecifiers / NoFieldSpecifiers ]], basic.choice("list", "none") )
rule([[ NoFieldSpecifiers <- "" ]])
rule([[ SomeFieldSpecifiers <- LBracket _ FieldSpecifierList _ RBracket ]], basic.forward(3))
rule([[ FieldSpecifierList <- FieldSpecifier (_ Comma _ FieldSpecifier)* ]], basic.listFilter)
rule([[ FieldSpecifier <- MemberPrivate / MemberProtected / MemberStatic ]], basic.match )

rule([[ EndClassKeyword <- 'end' ]], function()
	-- pop the stored return value from the class stack and return it
	return {retn = table.remove(classStack)}
end )
