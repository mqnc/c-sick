
rule([[ ClassDeclaration <- ClassKeyword _ ParametrizedClassName _ Inheritance? _ SilentTerminal ClassBody EndClassKeyword ]], classGenerator )

table.insert(globalStatements, "ClassDeclaration")

rule([[ ClassKeyword <- "class" ]], function(sv, info)
	table.insert(classStack, {})
	return {}
end )

rule([[ ParametrizedClassName <- Identifier (_ LTypeBrace _ IdentifierList _ RTypeBrace)* ]], function(sv, info)
	classStack[#classStack].name = sv[1].txt
	return basic.listFilter(sv, info)
end )

rule([[ Inheritance <- InheritKeyword _ InheritanceList ]], basic.concat)
rule([[ InheritKeyword <- "inherits" ]])
rule([[ InheritanceList <- InheritanceListItem (_ Comma _ InheritanceListItem)* ]], basic.concat)
rule([[ InheritanceListItem <- Type _ AccessMode ]], "{3} {1}")
rule([[ AccessMode <- AccessModePublic / AccessModePrivate / AccessModeProtected ]], basic.concat)
rule([[ AccessModePublic <- '' ]], "public")
rule([[ AccessModePrivate <- LBracket _ "private" _ RBracket ]], "private")
rule([[ AccessModeProtected <- LBracket _ "protected" _ RBracket ]], "protected")

rule([[ ClassBody <- Skip (!EndKeyword ClassMemberDeclaration Skip)* ]], basic.concat )

--rule([[ ClassMemberDeclaration <- FieldDeclaration / MethodDeclaration / OperatorDeclaration ]], basic.concat )
rule([[ ClassMemberDeclaration <- FieldDeclaration / OperatorDeclaration ]], basic.concat )

--rule([[ OperatorDeclaration <- CtorDeclaration / DtorDeclaration / CopyDeclaration / AssignDeclaration / CallDeclaration / AccessDeclaration ]], basic.concat )
rule([[ OperatorDeclaration <- CtorDeclaration ]], basic.concat )

-- CONSTRUCTOR

rule([[ CtorDeclaration <- CtorKeyword _ MemberSpecifiers _ Parameters _ Terminal Skip Inits CtorBody EndKeyword ]], ctorGenerator )

rule([[ Inits <- InitList / Delegation / NoInits ]], basic.choice("init", "delegate", "none") )
rule([[ NoInits <- "" ]])

rule([[ CtorKeyword <- "ctor" ]])

rule([[ MemberSpecifiers <- (LBracket _ MemberSpecifierList _ RBracket) / NoMemberSpecifiers ]], basic.choice("list", "none") )
rule([[ NoMemberSpecifiers <- "" ]])
rule([[ MemberSpecifierList <- MemberSpecifier (_ Comma _ MemberSpecifier)* ]], basic.listFilter)
rule([[ MemberSpecifier <- MemberConst / MemberPrivate / MemberProtected / MemberVirtual / MemberOverride / MemberInline / MemberStatic / MemberKwargs ]])

rule([[ MemberConst <- "const" ]])
rule([[ MemberPrivate <- "private" ]])
rule([[ MemberProtected <- "protected" ]])
rule([[ MemberVirtual <- "virtual" ]])
rule([[ MemberOverride <- "override" ]])
rule([[ MemberInline <- "inline" ]])
rule([[ MemberStatic <- "static" ]])
rule([[ MemberKwargs <- "kwargs" ]])

rule([[ InitList <- InitKeyword _ Terminal _ FieldAssignmentList _ EndKeyword ]], basic.concat)
rule([[ InitKeyword <- "init" ]])
rule([[ FieldAssignmentList <- FieldAssignment _ Terminal (_ FieldAssignment _ Terminal)* ]], basic.concat)
rule([[ FieldAssignment <- Identifier _ AssignOperator _ Assigned ]], basic.concat )

rule([[ Delegation <- CtorKeyword _ Parameters _ Terminal ]], basic.concat )

rule([[ CtorBody <- Skip (!EndKeyword LocalStatement Skip)* ]], basic.concat )

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
