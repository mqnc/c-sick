
grammar = {}
actions = {}

function rule(r)
	grammar[1 + #grammar] = r
end

rule([[ Start <- nl (GlobalToken)* _ nl ]])

rule([[ Comment <- <SingleLineComment / MultiLineComment / NestableComment> ]])
rule([[ SingleLineComment <- '//' (!NL .)* NL ]])
rule([[ MultiLineComment <- '/*' (!'*/' .)* '*/' ]])
rule([[ NestableComment <- '\\*' (NestableComment / !'*\\' .)* '*\\' ]])

rule([[ AssignOperator <- ':=' ]])
rule([[ Identifier <- <([a-zA-Z_] [a-zA-Z_0-9]* / VerbatimCpp)> _ ]])

rule([[ GlobalToken <- VerbatimCpp / GlobalDeclaration ]])

rule([[ VerbatimCpp <- CppLimiter CppCode* CppLimiter _ ]])
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

function subws(text)
	result = text
	result = string.gsub(result, " ", "&nbsp;")
	result = string.gsub(result, "\t", "&nbsp;&nbsp;&nbsp;&nbsp;")
	result = string.gsub(result, "\n", "<br>")
	return result
end

function divwrap(params)
	content = ""
	if #params.tokens > 0 then
		content = subws(table.concat(params.tokens, ""))
	elseif #params.values > 0 then
		content = table.concat(params.values, "")
	else
		content = subws(params.matched)
	end
	content = "<div title=\"" .. params.rule .. "\">" .. content .. "</div>"
	content = string.gsub(content, "<br></div>", "</div><br>") -- propagate newline outside block
	content = string.gsub(content, "\"></div>", "\">&epsilon;</div>")
	return content
end

function matched(params)
	return subws(params.matched)
end

actions["WS"] = matched
actions["_"] = matched
actions["NL"] = matched
actions["nl"] = matched

pp = pegparser{
	grammar = table.concat(grammar, "\n"),
	actions = actions,
	default = divwrap,
	packrat = true,
	debuglog = false}

function writeToFile(fname, text)
	fout = io.open(fname, "w")
	io.output(fout)
	io.write(text)
	io.close(fout)
end

htmlHeader = [[
<html>
	<head>
		<title>Parsing Result</title>
		<style>
			div{
				display: inline-block;
				font-family:monospace;
				background-color:rgba(0,100,255,0.05);
				border:solid 1px rgba(0,100,255,0.3);
				margin:3px;
				cursor: default;
			}
			div:hover {
				background-color:rgba(255,0,0,0.08);
				border:solid 1px red;
			}
		</style>
	</head>
	<body>

]]

htmlFooter = [[

	</body>
</html>
]]

if false then
print("testing verbatim c++...")
result = pp:parse([[
$int main(){
	// $
	/* $ // */
	'\'';
	'$';
	"\\\"$";
	R"raw( )boiled" $ )raw";
}$
]])
writeToFile("test/output/verbatim_cpp.html", htmlHeader .. result .. htmlFooter)

print("testing global declarations...")
result = pp:parse([[
q := X
int q := X
const unsigned int q := X
]])
writeToFile("test/output/global_decl.html", htmlHeader .. result .. htmlFooter)
end

print("testing function declarations...")
result = pp:parse([[
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
writeToFile("test/output/function_decl.html", htmlHeader .. result .. htmlFooter)
