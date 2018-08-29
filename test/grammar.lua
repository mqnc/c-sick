
grammar = {}
actions = {}

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

input = readAll("test/language.txt")

-- for little tests:
input2 = [[

]]

debuglog = false

function rule(r)
	grammar[1 + #grammar] = r
end

rule([[ Start <- skip (GlobalToken skip)* ]])
--rule([[ Start <- _ IfStatement skip]])

rule([[ SyntaxError <- (!nl .)* nl ]])

rule([[ Comment <- SingleLineComment / MultiLineComment / NestableComment ]])
rule([[ SingleLineComment <- '//' (!nl .)* ]])
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ NestableComment <- '\\*' (NestableComment / !'*\\' .)* '*\\' ]])

rule([[ AssignOperator <- ':=' ]])
rule([[ Identifier <- ([a-zA-Z_] [a-zA-Z_0-9]* / VerbatimCpp) ]])

rule([[ GlobalToken <- (VerbatimCpp _ break) / GlobalDeclaration / SyntaxError ]])
rule([[ LocalToken <- Statement / SyntaxError ]])

rule([[ VerbatimCpp <- CppLimiter CppCode* CppLimiter ]])
rule([[ CppLimiter <- '$' ]])
rule([[ CppCode <- CppComment / CppStringLiteral / CppAnything ]])
rule([[ CppComment <- CppSingleLineComment / CppMultiLineComment ]])
rule([[ CppSingleLineComment <- '//' (!nl .)* nl ]])
rule([[ CppMultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ CppStringLiteral <- CppCharConstant / CppSimpleString / CppMultiLineString ]])
rule([[ CppCharConstant <- '\'' (('\\' .) / .) '\'' ]])
rule([[ CppSimpleString <- '"' (('\\' .) / (!'"' .))* '"' ]])
rule([[ CppMultiLineString <- 'R"' $delim[a-zA-Z_0-9]* '(' (!(')' $delim '"') .)* ')' $delim '"' ]])
rule([[ CppAnything <- (!CppLimiter .) ]])

rule([[ GlobalDeclaration <- FunctionDeclaration / SimpleDeclaration ]])

rule([[ SimpleDeclaration <- (Specifier ws)* Declaree _ (AssignOperator _ Placeholder _)? break ]])
rule([[ Specifier <- !Declaree Identifier ]])
rule([[ Declaree <- Identifier _ (&AssignOperator / &break) ]])

rule([[ FunctionDeclaration <- FunctionKeyword ws Identifier _ OptionalSpecifierList _ OptionalParameters _ OptionalReturnValues _ break OptionalFunctionBody EndFunction _ break ]])
rule([[ FunctionKeyword <- 'function' ]])
rule([[ OptionalSpecifierList <- ('[' _ (Identifier _)* ']' )? ]])
rule([[ OptionalParameters <- ('(' _ ParameterDeclarationList _ ')')? ]])
rule([[ ParameterDeclarationList <- ParameterDeclaration (',' _ ParameterDeclaration)* / _ ]])
rule([[ ParameterDeclaration <- (ParameterSpecifier _)* Parameter _ (AssignOperator _ Placeholder)? ]])
rule([[ ParameterSpecifier <- !Parameter Identifier ]])
rule([[ Parameter <- Identifier _ (&AssignOperator / &',' / &')') ]])
rule([[ OptionalReturnValues <- ('->' _ (SingleReturnValue / MultipleReturnValues))? ]])
rule([[ SingleReturnValue <- ParameterDeclaration ]])
rule([[ MultipleReturnValues <- '(' _ ReturnValueList _ ')' ]])
rule([[ ReturnValueList <- ParameterDeclaration _ (',' _ ParameterDeclaration _)* / _ ]])
rule([[ OptionalFunctionBody <- skip (!EndFunction LocalToken skip)*  ]])
rule([[ EndFunction <- 'end' ]])

rule([[ Statement <- IfStatement ]])

rule([[ IfStatement <- IfPart (ElseIfPart)* ElsePart? EndIf ]])
rule([[ IfPart <- IfKeyword ws Condition _ break OptionalIfBody ]])
rule([[ IfKeyword <- 'if' ]])
rule([[ Condition <- Placeholder ]])
rule([[ OptionalIfBody <- skip (!ElseIfKeyword !ElseKeyword !EndIf LocalToken skip)* ]])
rule([[ ElseIfPart <- ElseIfKeyword ws Condition _ break OptionalIfBody ]])
rule([[ ElseIfKeyword <- 'elseif' ]])
rule([[ ElsePart <- ElseKeyword _ break OptionalIfBody ]])
rule([[ ElseKeyword <- 'else' ]])
rule([[ EndIf <- 'end' ]])

rule([[ ws <- ([ \t] / ('...' _ break) / Comment)* # definite whitespace ]])
rule([[ _ <- ws? # optional whitespace ]])
rule([[ nl <- '\r\n' / '\n' # definite whitespace ]])
rule([[ break <- nl / ';' # end of something ]])
rule([[ skip <- _ (nl _)* # consume all new lines and whitespaces (and comments) ]])

rule([[ Placeholder <- [0-9]* _ ]])

function htmlwrap(params)
	chain = params.matched

	chain = string.gsub(chain, "<", string.char(17)) -- substitute so html wont be messed up
	chain = string.gsub(chain, ">", string.char(18)) -- replace with single character so positions remain unchanged

	for i = #params.values, 1, -1 do
		p1 = params.values[i].subpos-params.position
		p2 = p1+params.values[i].sublen
		sub = params.values[i].subtxt
		chain = string.sub(chain, 1, p1) .. "</p>" .. sub .. "<p>" .. string.sub(chain, p2+1)
	end

	chain = string.gsub(chain, string.char(17), "&lt;") -- now render < and > in html
	chain = string.gsub(chain, string.char(18), "&gt;")

	chain = "<div_title=\"" .. params.rule .. "\"><p>" .. chain .. "</p></div>"
	return {subpos=params.position, sublen=params.length, subtxt=chain, rule=params.rule}
end

actions["SyntaxError"] = function(params)
	html = htmlwrap(params)
	html.subtxt = string.gsub(html.subtxt, "<p>", "<p_class=\"error\">")
	return html
end

actions["Start"] = function(params)
	content = htmlwrap(params).subtxt

	content = string.gsub(content, "<p></p>", "")
	content = string.gsub(content, " ", "&#x2423;")
	content = string.gsub(content, "\t", "&xrarr;")
	content = string.gsub(content, "\n", "&ldsh;<br>\n")
	content = string.gsub(content, "<div_title=", "<div title=")
	content = string.gsub(content, "<p_class=", "<p class=")

	content = [[
<html>
	<head>
		<title>Parsing Result</title>
		<style>
			div{
				background-color:rgba(96,192,255,0.1);
				border:solid 1px rgba(0,0,0,0.1);
				display:inline;
				font-family:monospace;
				font-size:82%;
				padding-left:3pt;
				padding-right:3pt;
				margin-left:2pt;
				margin-right:2pt;
			}
			div.mark, div.mark div{
				background-color:rgba(255,128,0,0.4);
			}
			p{
				pointer-events: none;
				display:inline;
				font-size:12pt;
			}
			p.error{
				color:#CC0000;
			}
			#info{
				pointer-events: none;
				display:block;
				position:fixed;
				top:30px;
				right:30px;
				border:solid 1px black;
				background-color:#ffffaa;
				font-size:14pt;
				font-family:monospace;
				padding:20pt;
				visibility:hidden;
			}
			#explorer{
				font-size:30pt;
				line-height:25pt
			}
		</style>
	</head>
	<body>
		<span id="info"></span>
		<span id="explorer">


]] .. content .. [[


		</span>
		<script>
			var divs = document.getElementsByTagName("div");
			var info = document.getElementById("info");

			for(var i=0; i<divs.length; i++){
				divs[i].onmouseover = function(evt){
					evt.target.className="mark";
					info.style.visibility = "visible";
					info.innerHTML = evt.target.title;
					parent = evt.target.parentElement;
					while(parent.id != "explorer"){
						info.innerHTML = parent.title + "<br>" + info.innerHTML;
						parent = parent.parentElement;
					}
				}
				divs[i].onmouseout = function(evt){
					info.innerHTML = "";
					info.style.visibility = "hidden";
					evt.target.className="";
				}
			}
		</script>
	</body>
</html>

]]
	return content
end

pp = pegparser{
	grammar = table.concat(grammar, "\n"),
	actions = actions,
	default = htmlwrap,
	packrat = true,
	debuglog = debuglog}

function writeToFile(fname, text)
	fout = io.open(fname, "w")
	io.output(fout)
	io.write(text)
	io.close(fout)
end

output = pp:parse(input)

writeToFile("test/output.html", output)
