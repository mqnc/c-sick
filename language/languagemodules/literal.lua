
rule([[ Literal <- Boolean / CharLiteral / StringLiteral / NumericLiteral ]], basic.first )

rule([[ Boolean <- "true" / "false" ]], basic.match )
table.insert(keywords, "Boolean")

rule([[ CharLiteral <- '\'' (('\\' .) / .) '\'' ]], basic.match )

rule([[ StringLiteral <- '"' (('\\' .) / (!'"' .))* '"' ]], basic.match )

rule([[ NumericLiteral <- FloatLiteral / HexLiteral / IntegerLiteral ]], basic.first )
rule([[ IntegerLiteral <- [0-9]+ ]], basic.match )
rule([[ FloatLiteral <- [0-9]+ '.' [0-9]+ (('e' / 'E') '-'? [0-9]+)? ]], basic.match )
rule([[ HexLiteral <- '0' ('x' / 'X') [0-9]+ ]], basic.match )
