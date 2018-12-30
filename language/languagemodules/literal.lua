--[[
This module provides literals:
true and false
'c' for chars
"string" for strings
123 for integers
0x123 for hex notation of integers
123.456e78 for doubles
future plans include:
123.456x10^78
some way for verbatim multiline string literals, probably the cpp one
]]

rule([[ Literal <- Boolean / CharLiteral / StringLiteral / NumericLiteral ]], basic.first )

rule([[ Boolean <- "true" / "false" ]], basic.match )
table.insert(keywords, "Boolean")

rule([[ CharLiteral <- '\'' (('\\' .) / .) '\'' ]], basic.match )

rule([[ StringLiteral <- '"' (('\\' .) / (!'"' .))* '"' ]], basic.match )

rule([[ NumericLiteral <- FloatLiteral / HexLiteral / IntegerLiteral ]], basic.first )
rule([[ IntegerLiteral <- [0-9]+ ]], basic.match )
rule([[ FloatLiteral <- [0-9]+ '.' [0-9]+ (('e' / 'E') '-'? [0-9]+)? ]], basic.match )
rule([[ HexLiteral <- '0' ('x' / 'X') [0-9]+ ]], basic.match )
