
rule([[ Start <- {skip} ({GlobalStatement} {skip})* ]], basic.subs )

rule([[ Comment <- {SingleLineComment} / {MultiLineComment} / {NestableComment} ]], basic.subs )
rule([[ SingleLineComment <- '//' (!nl .)* ]], basic.match )
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]], basic.match )
rule([[ NestableComment <- '\\*' <(NestableComment / !'*\\' .)*> '*\\' ]],
    function(params)
        return "/*" .. params.tokens[1]:gsub("/[*]", "\\*"):gsub("[*]/", "*\\") .. "*/"
    end
)

table.insert(identifiers, "{Name}")
rule([[ Name <- NameStart NameMid* NameEnd ]], basic.match )
rule([[ NameStart <- [a-zA-Z_] ]])
rule([[ NameMid <- [a-zA-Z_0-9] ]])
rule([[ NameEnd <- !NameMid ]])

rule([[ SimpleDeclaration <- DeclarationWithInit / DeclarationWithoutInit ]], basic.subs )
rule([[ DeclarationWithInit <- {Identifier} _ ({Identifier} _)+ {AssignOperator} _ {Expression} _ {break} ]], basic.subs )
rule([[ DeclarationWithoutInit <- {Identifier} _ ({Identifier} _)+ {break} ]],
	function(params)
		local i = 1
		local specifiers = {}
		while params.values[i].rule == "Identifier"
			table.insert(specifiers, params.values[i].output)
			i = i+1
		end
		local variable = 
	end
)
table.insert(globalStatements, "{SimpleDeclaration}")
table.insert(localStatements, "{SimpleDeclaration}")
rule([[ Assignment <- {Identifier} _ {AssignOperator} _ {Expression} _ {break} ]], basic.subs )
table.insert(globalStatements, "{Assignment}")
table.insert(localStatements, "{Assignment}")
rule([[ AssignOperator <- ':=' ]], " = " )
rule([[ Expression <- [0-9]+ / {Identifier} ]], basic.subs )
table.insert(localStatements, "{Expression}")

rule([[ ws <- ([ \t] / ('...' _ nl) / {Comment})* ]], basic.subs ) -- definite whitespace
rule([[ _ <- {ws}? ]], basic.subs ) -- optional whitespace
rule([[ nl <- '\r\n' / '\n' / !. ]], "\n" ) -- definite new line
rule([[ break <- nl / ';' ]], ";\n")
rule([[ skip <- {_} (nl {_})* ]], basic.subs ) -- consume all new lines and whitespaces (and comments)
