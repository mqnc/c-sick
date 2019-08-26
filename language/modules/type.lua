

rule([[ Type <- TypeofExpression / ParametrizedType ]], basic.forward(1) )
rule([[ TypeofExpression <- Typeof _ LParen _ Expression _ RParen ]], basic.concat )
rule([[ Typeof <- "typeof" ]], "decltype" )
rule([[ ParametrizedType <- Identifier (_ RTypeBrace _ TemplateParameterList _ LTypeBrace)* ]], basic.concat )
rule([[ TemplateParameterList <- Type (_ Comma _ Type)* ]], basic.concat )

rule([[ LTypeBrace <- LBrace ]], "<" )
rule([[ RTypeBrace <- RBrace ]], ">" )
