
rule([[ Cinnamon <- Skip (GlobalStatement Skip)* ]], basic.concat )

-- syntax error has to be added to the list of statements after everything else
rule([[ SyntaxError <- (!NewLine .)* NewLine ]],  col("{match}", "brightred") )
--rule([[ SyntaxError <- (!nl .)* nl ]],  "//!\\\\{match}" )

rule([[ NewLine <- '\r\n' / '\n' ]], '\n')
rule([[ LineBreak <- LineEndComment? NewLine ]], basic.concat )
rule([[ LineContinue <- '...' _ LineBreak ]], basic.concat )
rule([[ WhiteSpace <- [ \t]+ ]], " " )
rule([[ Space <- (WhiteSpace / InlineComment / LineContinue)+ ]], basic.concat ) -- definite space
rule([[ _ <- Space? ]], basic.concat ) -- optional space
rule([[ Semicolon <- ';' ]], '')
rule([[ SilentTerminal <- LineBreak / Semicolon ]], basic.first)
rule([[ Terminal <- SilentTerminal ]], ";{1}")

rule([[ Skip <- _ (LineBreak _)* ]], basic.concat ) -- consume all new lines and whitespaces (and comments)
rule([[ Comma <- ',' ]], ',')


rule([[ Comment <- LineEndComment / InlineComment ]], basic.concat)
rule([[ LineEndComment <- '//' (!NewLine .)* ]], basic.match) -- does not include line break
rule([[ InlineComment <- MultiLineComment / NestableComment ]], basic.concat)
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]], basic.match)
rule([[ NestableComment <- '(*' <(!'*)' (NestableComment / .))*> '*)' ]],
    function(arg)
		return {"/*" .. arg.tokens[1]:gsub("/[*]", "(*"):gsub("[*]/", "*)") .. "*/"}
    end
)


table.insert(identifiers, "Name")
rule([[ Name <- NameStart NameMid* NameEnd ]], basic.match )
rule([[ NameStart <- [a-zA-Z_] ]])
rule([[ NameMid <- [a-zA-Z_0-9] ]])
rule([[ NameEnd <- !NameMid ]])

-- note that a declaration does not include a trailing break
rule([[ SimpleDeclaration <- DeclarationWithInit / DeclarationWithoutInit ]], basic.first )

local declarationAction = function(arg)
	local resultTbl = basic.concat(arg)
	resultTbl.specifiers = {}

	local i = 1
	while #arg.values>=i and arg.values[i].rule == "Identifier" do
		table.insert(resultTbl.specifiers, arg.values[i][1])
		i = i+2 -- consider comments
	end
	-- i now points to the assign operator

	resultTbl.variable = resultTbl.specifiers[#resultTbl.specifiers]
	resultTbl.specifiers[#resultTbl.specifiers] = nil
	if arg.rule == "DeclarationWithInit" then
		resultTbl.init = arg.values[i+2][1]
	end

	return resultTbl
end

rule([[ DeclarationWithInit <- Identifier _ (Identifier _)+ AssignOperator _ Expression ]], declarationAction )
rule([[ DeclarationWithoutInit <- Identifier (_ Identifier)+ ]], declarationAction )
table.insert(globalStatements, "SimpleDeclaration _ Terminal")
table.insert(localStatements, "SimpleDeclaration _ Terminal")
rule([[ Assignment <- Identifier _ AssignOperator _ Expression _ Terminal ]], basic.concat )
table.insert(globalStatements, "Assignment")
table.insert(localStatements, "Assignment")
rule([[ AssignOperator <- ':=' ]], "=" )
rule([[ Expression <- Atomic ]], basic.concat )
-- expression will be added to the list of local statements later in order to check it last since it's such a recursion hole
rule([[ Atomic <- Identifier / Literal ]], basic.concat )
rule([[ Literal <- [0-9]+ ]], basic.match )
rule([[ ExpressionList <- Expression (_ Comma _ Expression)* ]], basic.tree )
