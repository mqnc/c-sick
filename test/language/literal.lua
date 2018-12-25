
rule([[ Literal <- {CharLiteral} / {StringLiteral} / {NumericLiteral} ]], basic.subs )

rule([[ CharLiteral <- '\'' (('\\' .) / .) '\'' ]], basic.match )

rule([[ StringLiteral <- '"' (('\\' .) / (!'"' .))* '"' ]], basic.match )

rule([[ NumericLiteral <- {FloatLiteral} / {HexLiteral} / {IntegerLiteral} ]], "{1}" )
rule([[ IntegerLiteral <- [0-9]+ ]], basic.match )
rule([[ FloatLiteral <- [0-9]+ '.' [0-9]+ (('e' / 'E') '-'? [0-9]+)? ]], basic.match )
rule([[ HexLiteral <- '0' ('x' / 'X') [0-9]+ ]], basic.match )
