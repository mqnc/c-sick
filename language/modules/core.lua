--[[
This module provides the core features of the language:
syntax errors
line breaks
white spaces
comments
terminators
words
identifiers
]]

rule([[ Cinnamon <- CinnamonHeader Skip (GlobalStatement Skip)* CinnamonFooter ]], basic.concat )
rule([[ CinnamonHeader <- '' ]], '#include "cinnamon.h"\n' )

-- syntax error has to be added to the list of statements after everything else
rule([[ SyntaxError <- (!NewLine .)* NewLine ]],  col("{match}", "brightred") )

rule([[ NewLine <- '\r\n' / '\n' ]], '\n')
rule([[ LineBreak <- LineEndComment? NewLine ]], basic.concat )
rule([[ Ellipsis <- '...' ]], ' ' )
rule([[ LineContinue <- Ellipsis _ LineBreak ]], basic.concat )
rule([[ WhiteSpace <- [ \t]+ ]], " " )
rule([[ Space <- (WhiteSpace / InlineComment / LineContinue)+ ]], basic.concat ) -- definite space
rule([[ _ <- Space? ]], basic.concat ) -- optional space
rule([[ Semicolon <- ';' ]], '')
rule([[ SilentTerminal <- LineBreak / Semicolon ]], basic.first)
rule([[ Terminal <- SilentTerminal ]], ";{1}")

rule([[ Skip <- _ (LineBreak _)* ]], basic.concat ) -- consume all new lines and whitespaces (and comments)

--rule([[ Comment <- LineEndComment / InlineComment ]], basic.concat)
rule([[ LineEndComment <- '//' (!NewLine .)* ]], basic.match) -- does not include line break
rule([[ InlineComment <- MultiLineComment / NestableComment ]], basic.concat)
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]], basic.match)
rule([[ NestableComment <- '(*' <(!'*)' (NestableComment / .))*> '*)' ]],
    function(arg)
		return {"/*" .. arg.tokens[1]:gsub("/[*]", "(*"):gsub("[*]/", "*)") .. "*/"}
    end
)

rule([[ Word <- WordStart WordMid* WordEnd ]], basic.match)
rule([[ WordStart <- [a-zA-Z_] ]], basic.match)
rule([[ WordMid <- [a-zA-Z_0-9] ]], basic.match)
rule([[ WordEnd <- !WordMid ]], "")

rule([[ Identifier <- !Keyword Word ]], basic.match )
rule([[ IdentifierList <- Identifier (_ IdentifierSep _ Identifier)* ]], basic.concat )
rule([[ IdentifierSep <- ',' ]], ',' )

-- this solution does not work with multiple cpp files yet but baby steps
rule([[ CinnamonFooter <- '' ]], 'int main(){return start();}' )
