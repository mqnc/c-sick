<img alt="Cinnamon" title="Cinnamon" src="https://github.com/mqnc/c-sick/blob/master/logo/cinnamon.png?raw=true" height=100 />

# Usable Programming Language on Top of C++

*in development*

## Workflow

A cinnamon source code file specifies in its header which language modules it uses. The language modules are Lua files which compose the grammar for the rest of the file. The grammar is then loaded into a peg parser which translates the file into C++ code.

## Usage

```
$ scons
$ cd language
$ ../program cinnamon.lua
```

## In Detail

The parser is written in C++ and can be found in src. It incorporates a Lua interpreter and constitutes the main program. A pegparser module is provided which can be called from inside Lua.

Everything else is contained in the language folder:

**transpiler.lua** is a module that wraps the parser and provides functions for grammar construction and parsing.

**cinnamon.lua** uses the transpiler, loads all the language modules contained in the languagemodules folder to construct the grammar, parses the all.mon file in the snippets folder and displays the transpiled result. Other language examples from the snippet folder can be tried by replacing all.mon with another file inside the code, as you would expect from a clean and usable program. The language modules are independent from each other. The core.lua module always has to be loaded at first, then other modules can be included at will. The order can become important though, as they can overwrite each other's grammar rules and it might happen that some language constructs should be tried by the parser before others, so their modules should be included first.

**prettify.lua** formats the line breaks, tabs and spaces in the cpp output.

**utils.lua** contains helper functions for file io, colored output on consoles and nice display of Lua data structures.

**parsertest.lua** was supposed to be a unit test for the c++ parser module but is constantly outdated.

The expression module **languagemodules/expression.lua** is special. It constructs its grammar from a table of operations of the following form:

```
OperatorClasses = {
	{
		name = "Access",
		order = "ltr",
		operators = {
			{peg="'(' ~_ ExpressionList ~_ ')'", cpp="({<})({1})"},
			{peg="'[' ~_ ExpressionList ~_ ']'", cpp="({<})[{1}]"},
			{peg="'.'", cpp="({<}).{>}"},
			{peg="'->'", cpp="({<})->{>}"}
		}
	}, {
		name = "Addition",
		order = "ltr",
		operators = {
			{peg="'+'", cpp="({<})+({>})"},
			{peg="'-'", cpp="({<})-({>})"}
		}
	}
}
```
All operator classes are listed by descending priority. So the operator class Multiplication containing * and / should come before the class Addition containing + and -.
_name_ defines the name of the operator class. _order_ specifies its associativity. _operators_ contains all operators of a class, they have equal priority. _peg_ is the syntax for the operator that will be included in the peg grammar, cpp is what will be written to the transpiler output cpp file. The special symbols {<}, {>} and {X} where X is a number are used to refer to arguments at the left or right side of the operator or semantic values inside of it. Whether an operator is infix or pre/postfix is derived from the appearance of {<} and {>} in its cpp part. Note that there can't be an ltr prefix or an rtl postfix operator.

## Dependencies

Cinnamon uses [Peglib](https://github.com/yhirose/cpp-peglib) and [Lua](https://www.lua.org/home.html), both of which are included. The build system requires [Scons](https://scons.org/).

## Todos

- The modular system for the grammar construction is so far just a bunch of dofile statements. Also, right now it loads just all modules for a file and there is no way to specify anything. All that needs redesign.

- The predecessors of Cinnamon were all producing lzz files which needed further processing by Lazy C++. However, the number of dependencies should be minimized and we want to be able to use the latest C++ features without relying on Lazy C++ being up-to-date and bug-free. So the Cinnamon transpiler will have to generate cpp and h files itself.

- Include kwargs and ranges by jkuebart.

- How to deal with classes, structs, pointers and references?

- Wrap destructuring assignments for function returns with multiple returns.

- The expression module needs a hook so custom operators can be included into the table of operations before turning it into peg grammar.

- Create a module for beautiful math syntax.

- Create a module for MATLAB-like matrix manipulation.

- Allow Unicode in identifiers.

- So far, the c++ parser outsources all actions to lua and passes things around as lua values. However, most actions either just return the matched string or concatenate all their semantic values. So it would be better to have everything in naked c++ with a native c++ struct containing all relevant information and only in case a special action is needed, a lua function is wrapped and called. However, for the prototype of the transpiler, things will remain in lua as they still change frequently.
