
rule([[ Cinnamon <- {skip} ({GlobalStatement} {skip})* ]], basic.subs )

rule([[ Comment <- {LineEndComment} / {InlineComment} ]], basic.subs )
rule([[ LineEndComment <- '//' <(!nl .)*> ]], basic.match )
rule([[ InlineComment <- {MultiLineComment} / {NestableComment} ]], basic.subs )
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]], basic.match )
rule([[ NestableComment <- '(*' <(NestableComment / !'*)' .)*> '*)' ]],
    function(arg)
		local result = sv(arg)
		result.str = "/*" .. arg.tokens[1]:gsub("/[*]", "(*"):gsub("[*]/", "*)") .. "*/"
		return result
    end
)

table.insert(identifiers, "{Name}")
rule([[ Name <- NameStart NameMid* NameEnd ]], basic.match )
rule([[ NameStart <- [a-zA-Z_] ]])
rule([[ NameMid <- [a-zA-Z_0-9] ]])
rule([[ NameEnd <- !NameMid ]])

-- note that a declaration does not include a trailing break
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
	while #arg.values>=i and arg.values[i].rule == "Identifier" do
		table.insert(result.specifiers, arg.values[i].str)
		i = i+1
	end
	i = i-1

	result.variable = result.specifiers[i]
	result.specifiers[i] = nil
	if arg.rule == "DeclarationWithInit" then
		result.init = arg.values[i+2].str
	end

	return result
end

rule([[ DeclarationWithInit <- {Identifier} _ ({Identifier} _)+ {AssignOperator} _ {Expression} ]], declarationAction )
rule([[ DeclarationWithoutInit <- {Identifier} (_ {Identifier})+ ]], declarationAction )
table.insert(globalStatements, "{SimpleDeclaration} _ {break}")
table.insert(localStatements, "{SimpleDeclaration} _ {break}")
rule([[ Assignment <- {Identifier} _ {AssignOperator} _ {Expression} _ {break} ]], basic.subs )
table.insert(globalStatements, "{Assignment}")
table.insert(localStatements, "{Assignment}")
rule([[ AssignOperator <- ':=' ]], " = " )
rule([[ Expression <- {Identifier} / {Literal} ]], basic.subs )
rule([[ Literal <- [0-9]+ ]], basic.subs )
rule([[ ExpressionList <- {Expression} (_ ',' _ {Expression})* ]], basic.forward )
table.insert(localStatements, "{Expression} _ {break}")

rule([[ ws <- ([ \t] / {InlineComment})* ]], basic.subs ) -- definite whitespace

-- continues disabled until I figured out how to deal with them
--rule([[ ws <- ([ \t] / {continue} / {InlineComment})* ]], basic.subs ) -- definite whitespace
--rule([[ continue <- ('...' _ nl) ]], " " )
rule([[ _ <- {ws}? ]], basic.subs ) -- optional whitespace
rule([[ nl <- {LineEndComment}? ('\r\n' / '\n' / !.) ]],
	function(arg)
		local result = sv(arg)
		if arg.values[1] then
			result.str = arg.values[1].str .. "\n"
		else
			result.str = "\n"
		end
		return result
	end
)
rule([[ break <- nl / ';' ]], ";\n")
rule([[ skip <- {_} (nl {_})* ]], basic.subs ) -- consume all new lines and whitespaces (and comments)
