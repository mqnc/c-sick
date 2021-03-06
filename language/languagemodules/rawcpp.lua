--[[
This module provides raw c++ code in the form of
$ i++; $ which can be in place of an identifier and therefore also be a statement.
]]

rule( [[ RawCpp <- CppDelimiter <CppCode*> CppDelimiter ]], basic.token )
rule( [[ CppDelimiter <- '$' ]] )
rule( [[ CppCode <- CppComment / CppStringLiteral / CppAnything ]] )
--rule( [[ CppComment <- CppSingleLineComment / CppMultiLineComment ]] )
rule( [[ CppComment <- CppMultiLineComment ]] ) -- $ number++ // increase number $ should work
rule( [[ CppSingleLineComment <- '//' (!NewLine .)* NewLine ]] )
rule( [[ CppMultiLineComment <- '/*' (!'*/' .)* '*/' ]] )
rule( [[ CppStringLiteral <- CppCharConstant / CppSimpleString / CppMultiLineString ]] )
rule( [[ CppCharConstant <- '\'' (('\\' .) / .) '\'' ]] )
rule( [[ CppSimpleString <- '"' (('\\' .) / (!'"' .))* '"' ]] )
rule( [[ CppMultiLineString <- 'R"' $delim<[a-zA-Z_0-9]*> '(' (!(')' $delim '"') .)* ')' $delim '"' ]] )
rule( [[ CppAnything <- (!CppDelimiter .) ]] )

table.insert(identifiers, "RawCpp")
