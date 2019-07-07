
rule([[ BooleanLiteral <- "true" / "false" ]], basic.match )
table.insert(literals, "BooleanLiteral")
table.insert(keywords, "BooleanLiteral")

rule([[ CharLiteral <- '\'' (('\\' .) / .) '\'' ]], basic.match )
table.insert(literals, "CharLiteral")

rule([[ StringLiteral <- '"' (('\\' .) / (!'"' .))* '"' ]], basic.match )
table.insert(literals, "StringLiteral")

rule([[ IntegerLiteral <- [0-9]+ ]], basic.match )
table.insert(literals, "IntegerLiteral")

rule([[ HexLiteral <- '0' ('x' / 'X') [0-9]+ ]], basic.match )
table.insert(literals, "HexLiteral")

rule([[ FloatLiteral <- [0-9]+ '.' [0-9]+ (('e' / 'E') '-'? [0-9]+)? ]], basic.match )
table.insert(literals, "FloatLiteral")
