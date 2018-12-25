
rule( [[ RawCpp <- CppDelimiter <CppCode*> CppDelimiter ]], basic.token )
rule( [[ CppDelimiter <- '$' ]] )
rule( [[ CppCode <- CppComment / CppStringLiteral / CppAnything ]] )
--rule( [[ CppComment <- CppSingleLineComment / CppMultiLineComment ]] )
rule( [[ CppComment <- CppMultiLineComment ]] ) -- $ number++ // increase number $ should work
rule( [[ CppSingleLineComment <- '//' (!nl .)* nl ]] )
rule( [[ CppMultiLineComment <- '/*' (!'*/' .)* '*/' ]] )
rule( [[ CppStringLiteral <- CppCharConstant / CppSimpleString / CppMultiLineString ]] )
rule( [[ CppCharConstant <- '\'' (('\\' .) / .) '\'' ]] )
rule( [[ CppSimpleString <- '"' (('\\' .) / (!'"' .))* '"' ]] )
rule( [[ CppMultiLineString <- 'R"' $delim<[a-zA-Z_0-9]*> '(' (!(')' $delim '"') .)* ')' $delim '"' ]] )
rule( [[ CppAnything <- (!CppDelimiter .) ]] )

table.insert(identifiers, "{RawCpp}")
