
rule([[ Start <- skip ({GlobalStatement} skip)* ]], basic.subs )

rule([[ SyntaxError <- (!nl .)* nl ]],  string.char(27) .. '[91m' .. "{match}" .. string.char(27) .. '[39m\n' )

rule([[ Comment <- {SingleLineComment} / {MultiLineComment} ]], basic.subs )
rule([[ SingleLineComment <- '//' (!nl .)* ]], basic.match )
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]], basic.match )
rule([[ NestableComment <- '\\*' (NestableComment / !'*\\' .)* '*\\' ]], basic.subs )

table.insert(identifiers, "Name")
rule([[ Name <- NameStart NameMid* NameEnd ]], basic.match )
rule([[ NameStart <- [a-zA-Z_] ]])
rule([[ NameMid <- [a-zA-Z_0-9] ]])
rule([[ NameEnd <- !NameMid ]])

table.insert(globalStatements, "SimpleDeclaration")
table.insert(localStatements, "SimpleDeclaration")
table.insert(localStatements, "Expression")
rule([[ SimpleDeclaration <- ({Identifier} _)+ ({AssignOperator} _ {Expression} _)? {break} ]])
rule([[ AssignOperator <- ':=' ]], " = " )
rule([[ Expression <- [0-9]+ ]], basic.match )

rule([[ ws <- ([ \t] / ('...' _ nl) / {Comment})* ]], basic.subs ) -- definite whitespace
rule([[ _ <- ws? ]], basic.subs ) -- optional whitespace
rule([[ nl <- '\r\n' / '\n' / !. ]], "\n" ) -- definite new line
rule([[ break <- nl / ';' ]], ";")
rule([[ skip <- _ (nl _)* ]], basic.subs ) -- consume all new lines and whitespaces (and comments)




--rule( [[ GlobalToken <- (RawCpp _ break) / GlobalDeclaration / SyntaxError ]], basic.subs )
--rule( [[ LocalToken <- (RawCpp _ break) / Statement / SyntaxError ]], basic.subs )
--rule( [[ Keyword <- (FunctionKeyword / EndFunctionKeyword / IfKeyword / ElseIfKeyword / ElseIfKeyword / EndIfKeyword / SwitchKeyword / CaseKeyword / FallKeyword / DefaultKeyword / EndSwitchKeyword / WhileKeyword / EndWhileKeyword / RepeatKeyword / RepWhileKeyword / UntilKeyword) NameEnd ]], basic.rule )

--rule( [[ Identifier <- !Keyword (Name / RawCpp) ]], basic.subs )
--rule( [[ Statement <- LocalDeclaration / IfStatement / SwitchStatement / WhileStatement / RepeatStatement / Expression ]], basic.subs )
