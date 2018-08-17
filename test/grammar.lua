
grammar = {}
actions = {}

function rule(r)
	grammar[1 + #grammar] = r
end

rule([[ Start <- nl (GlobalToken)* _ nl ]])

rule([[ SyntaxError <- (!'\n' .)* '\n' ]])

rule([[ Comment <- <SingleLineComment / MultiLineComment / NestableComment> ]])
rule([[ SingleLineComment <- '//' (!NL .)* NL ]])
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ NestableComment <- '\\*' (NestableComment / !'*\\' .)* '*\\' ]])

rule([[ AssignOperator <- ':=' ]])
rule([[ Identifier <- <([a-zA-Z_] [a-zA-Z_0-9]* / VerbatimCpp)> _ ]])

rule([[ GlobalToken <- VerbatimCpp / GlobalDeclaration / SyntaxError ]])

rule([[ VerbatimCpp <- CppLimiter CppCode* CppLimiter nl ]])
rule([[ CppLimiter <- '$' ]])
rule([[ CppCode <- CppComment / CppStringLiteral / CppAnything ]])
rule([[ CppComment <- <CppSingleLineComment / CppMultiLineComment> ]])
rule([[ CppSingleLineComment <- '//' (!NL .)* NL ]])
rule([[ CppMultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ CppStringLiteral <- <CppCharConstant / CppSimpleString / CppMultiLineString> ]])
rule([[ CppCharConstant <- '\'' (('\\' .) / .) '\'' ]])
rule([[ CppSimpleString <- '"' (('\\' .) / (!'"' .))* '"' ]])
rule([[ CppMultiLineString <- 'R"' $delim<[a-zA-Z_0-9]*> '(' (!(')' $delim '"') .)* ')' $delim '"' ]])
rule([[ CppAnything <- (!CppLimiter .) ]])

rule([[ GlobalDeclaration <- (SimpleDeclaration / FunctionDeclaration) _ ]])

rule([[ SimpleDeclaration <- Specifier* Declaree (AssignOperator _ Placeholder)? NL ]])
rule([[ Specifier <- !Declaree Identifier ]])
rule([[ Declaree <- Identifier (&AssignOperator / &NL) ]])

rule([[ FunctionDeclaration <- FunctionKeyword WS Identifier OptionalSpecifierList OptionalParameters OptionalReturnValues OptionalBody FunctionEnd NL ]])
rule([[ FunctionKeyword <- 'function' ]])
rule([[ OptionalSpecifierList <- ('[' _ Identifier* ']' )? _  ]])
rule([[ OptionalParameters <- ('(' _ ParameterDeclarationList ')')? _  ]])
rule([[ ParameterDeclarationList <- ParameterDeclaration (',' _ ParameterDeclaration)* / _ ]])
rule([[ ParameterDeclaration <- ParameterSpecifier* Parameter (AssignOperator _ Placeholder)? ]])
rule([[ ParameterSpecifier <- !Parameter Identifier ]])
rule([[ Parameter <- Identifier (&AssignOperator / &',' / &')') ]])
rule([[ OptionalReturnValues <- ('->' _ (SingleReturnValue / MultipleReturnValues))? _ ]])
rule([[ SingleReturnValue <- ParameterDeclaration _ ]])
rule([[ MultipleReturnValues <- '(' _ ReturnValueList ')' _ ]])
rule([[ ReturnValueList <- ParameterDeclaration (',' _ ParameterDeclaration)* / _ ]])
rule([[ OptionalBody <- AssignOperator nl (!FunctionEnd .)*  ]])
rule([[ FunctionEnd <- 'end' ]])

rule([[ WS <- <([ \t] / ('...' _ NL) / Comment)> # definite whitespace ]])
rule([[ _ <- WS? # optional whitespace ]])
rule([[ NL <- <([;\n] _)+> # definite new line (consuming all new lines) ]])
rule([[ nl <- NL? _ # optional new line ]])

rule([[ Placeholder <- <'X'> _ ]])

function htmlwrap(params)
	chain = params.matched

	for i = #params.values, 1, -1 do
		p1 = params.values[i].subpos-params.position
		p2 = p1+params.values[i].sublen
		sub = params.values[i].subtxt
		chain = string.sub(chain, 1, p1) .. "</p>" .. sub .. "<p>" .. string.sub(chain, p2+1)
	end

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
	debuglog = false}

function writeToFile(fname, text)
	fout = io.open(fname, "w")
	io.output(fout)
	io.write(text)
	io.close(fout)
end



result = pp:parse([[

$int main(){
	// $
	/* $ // */
	'\'';
	'$';
	"\\\"$";
	R"raw( )boiled" $ )raw";
}$


q := X
int q := X
I'm a syntax error
const unsigned int q := X


function fun0 end

function fun1 :=
end

function fun2() :=
end

function fun3(int x) :=
end

function fun4(int x:=X) :=
end

function fun5(int x:=X, int y) :=
end

function fun6 -> int q :=
end

function fun7 -> int q:=X :=
end

function fun8 -> (int q) :=
end

function fun9 -> (int q:=X) :=
end

function fun10 -> (int q:=X, int r) :=
end

function fun11(int x:=X, int y) -> (int q:=X, int r) :=
end
]])

writeToFile("test/output.html", result)
