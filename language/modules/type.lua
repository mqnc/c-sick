

rule([[ Type <- TypeofExpression / ParametrizedType ]], basic.forward(1) )
rule([[ TypeofExpression <- Typeof _ LParen _ Expression _ RParen ]], basic.concat )
rule([[ Typeof <- "typeof" ]], "remRefDecltype" )
rule([[ ParametrizedType <- Identifier (_ LTypeBrace _ TemplateParameterList _ RTypeBrace)* ]], basic.concat )
rule([[ TemplateParameterList <- Type (_ Comma _ Type)* ]], basic.concat )

rule([[ LTypeBrace <- LBrace ]], "<" )
rule([[ RTypeBrace <- RBrace ]], ">" )
