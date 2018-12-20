
rule([[ Start <- {skip} ({GlobalStatement} {skip})* ]], basic.subs )

rule([[ Comment <- {SingleLineComment} / {MultiLineComment} / {NestableComment} ]], basic.subs )
rule([[ SingleLineComment <- '//' (!nl .)* ]], basic.match )
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]], basic.match )
rule([[ NestableComment <- '\\*' <(NestableComment / !'*\\' .)*> '*\\' ]],
    function(arg)
		local result = sv.new(arg)
		result.str = "/*" .. arg.tokens[1]:gsub("/[*]", "\\*"):gsub("[*]/", "*\\") .. "*/"
		return result
    end
)

table.insert(identifiers, "{Name}")
rule([[ Name <- NameStart NameMid* NameEnd ]], basic.match )
rule([[ NameStart <- [a-zA-Z_] ]])
rule([[ NameMid <- [a-zA-Z_0-9] ]])
rule([[ NameEnd <- !NameMid ]])

rule([[ SimpleDeclaration <- {DeclarationWithInit} / {DeclarationWithoutInit} ]],
	function(arg)
		local result = arg.values[1]
		result.rule = arg.rule
		return result
	end
)

local declarationAction = function(arg)
	local result = basic.subs(arg)
	result.specifiers = {}

	local i = 1
	while arg.values[i].rule == "Identifier" do
		table.insert(result.specifiers, arg.values[i].str)
		i = i+1
	end
	i = i-1

	result.variable = result.specifiers[i]
	result.specifiers[i] = nil
	if arg.rule == "DeclarationWithInit" then
		result.init = arg.values[i+2].str
	else
		result.init = nil
	end

	return result
end

rule([[ DeclarationWithInit <- {Identifier} _ ({Identifier} _)+ {AssignOperator} _ {Expression} _ {break} ]], declarationAction )
rule([[ DeclarationWithoutInit <- {Identifier} _ ({Identifier} _)+ {break} ]], declarationAction )
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
