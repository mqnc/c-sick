
rule([[ ClassDeclaration <- ClassKeyword _ ParametrizedClassName _ Inheritance? _ SilentTerminal ClassBody EndKeyword ]], function(sv, info)
	dump(sv)
end )

table.insert(globalStatements, "ClassDeclaration")

rule([[ ClassKeyword <- "class" ]])

rule([[ ParametrizedClassName <- Identifier (_ LTypeBrace _ IdentifierList _ RTypeBrace)* ]], basic.listFilter )

rule([[ Inheritance <- InheritKeyword _ InheritanceList ]], basic.concat)
rule([[ InheritKeyword <- "inherits" ]])
rule([[ InheritanceList <- InheritanceListItem (_ Comma _ InheritanceListItem)* ]], basic.concat)
rule([[ InheritanceListItem <- Type _ AccessMode ]], "{3} {1}")
rule([[ AccessMode <- AccessModePublic / AccessModePrivate / AccessModeProtected ]], basic.concat)
rule([[ AccessModePublic <- '' ]], "public")
rule([[ AccessModePrivate <- LBracket _ "private" _ RBracket ]], "private")
rule([[ AccessModeProtected <- LBracket _ "protected" _ RBracket ]], "protected")

rule([[ ClassBody <- Skip ]])
