#include <iostream>
#include <fstream>
#include <string>
#include "lua/src/lua.hpp"
#include "luautils.h"
#include "stringutils.h"
#include "peglib.h"

#define DEBUG_PARSER // display each step of the parsing process
#define DEBUG_STRLEN 40 // display that many chars of the parsing text in debug output

using namespace peg;
using namespace std;


void registerReductionRule(parser *pegParser, lua_State *L, const string& rule, const string& funcName){
	// rule = the name of the PEG definition that invoked the reduction rule (NAME <- A / B / C)
	// funcName = the name of the associated action in lua's globals registry

	(*pegParser)[rule.c_str()] = [&L, rule, funcName](const SemanticValues& sv, any& dt){

		cout << funcName << endl;

		// find function
		lua_getglobal(L, funcName.c_str()); // <- crashes

		cout << lua_isfunction(L, -1) << endl;

		// push input parameters on stack
		lua_newtable(L);
			lua_pushfield(L, "rule", rule);
			lua_pushfield(L, "matched", StringPtr(sv.c_str(), sv.length()));
			lua_pushfield(L, "line", sv.line_info().first);
			lua_pushfield(L, "column", sv.line_info().second);
			lua_pushfield(L, "choice", sv.choice());

			lua_opensubtable(L, "values");
				for (size_t i = 0; i != sv.size(); ++i){
					lua_pushfield(L, 1+i, sv[i].get<LuaStackPtr>());
				}
			lua_closefield(L);

			lua_opensubtable(L, "tokens");
				for (size_t i = 0; i != sv.tokens.size(); ++i) {
					lua_pushfield(L, 1+i, StringPtr(sv.tokens[i].first, sv.tokens[i].second));
				}
			lua_closefield(L);

		// call lua function
		if (lua_pcall(L, 1, 1, 0)){
			cerr << "error invoking rule: " << lua_tostring(L, -1) << endl;
		}

		// return lua value
		return LuaStackPtr(lua_gettop(L));
	};
}

int makeParser(lua_State *L){

	// read grammar
	const char* grammar = lua_tostring(L, 1);
	parser *pegParser = new parser(grammar);


	// read default action

	lua_pushvalue(L, 3); // copy the function handle to top
	string defaultFuncName = ptr2str(lua_topointer(L, -1)); // use the address of the function as its name
	lua_setglobal(L, defaultFuncName.c_str()); // store function in lua globals (pops from stack)

	auto rules = pegParser->get_rule_names();
	for(auto& rule:rules){ // register default action for all PEG definitions
		registerReductionRule(pegParser, L, rule, defaultFuncName);
	}


	// read action table ( https://stackoverflow.com/questions/6137684/iterate-through-lua-table )
	lua_pushvalue(L, 2);
	lua_pushnil(L);
	while (lua_next(L, -2))
	{
		lua_pushvalue(L, -2);
		string rule = lua_tostring(L, -1); // = key
		string funcName = ptr2str(lua_topointer(L, -2)); // = value (use the address of the function as its name)
		lua_pop(L, 1); // pop key
		lua_setglobal(L, funcName.c_str()); // store function in lua globals (pops from stack)
		registerReductionRule(pegParser, L, rule, funcName);
	}
	lua_pop(L, 1);


	// configure parser
	pegParser->enable_packrat_parsing();


	// assign callbacks for parser debugging
	#ifdef DEBUG_PARSER
	for(auto& rule:rules){

		(*pegParser)[rule.c_str()].enter = [rule](const char* s, size_t n, any& dt) {
			auto& indent = *dt.get<int*>();
			cout << repeat("|  ", indent) << rule << " => \"" << shorten(s, n, DEBUG_STRLEN) << "\"?" << endl;
			indent++;
		};

		(*pegParser)[rule.c_str()].leave = [rule, &L](const char* s, size_t n, size_t matchlen, any& value, any& dt) {
			auto& indent = *dt.get<int*>();
			indent--;
			cout << repeat("|  ", indent) << "`-> ";
			if(success(matchlen)){

				// display "match", the matched string and the result of the reduction
				cout << "match: \"" << shorten(s, matchlen, DEBUG_STRLEN-2) << "\" -> ";
				lua_getglobal(L, "stringify");
				lua_push(L, value.get<LuaStackPtr>());
				lua_pcall(L, 1, 1, 0);
				string output = lua_tostring(L, -1);
				lua_pop(L, 1);
				cout << shorten(output.data(), output.size(), DEBUG_STRLEN) << endl;
			}
			else{
				cout << "failed" << endl;
			}
		};
	}
	pegParser->log = [&](size_t ln, size_t col, const string& msg) {
		cout << "(" << ln << "," << col << ") " << msg;
	};
	#endif


	// return parser
	lua_pushlightuserdata (L, pegParser);

	return 1;
}


int parse(lua_State *L){

	parser *pegParser = (parser*)lua_touserdata(L, 1); // pointer to parser
	string text = lua_tostring(L, 2); // text to parse

	any value;
	int indent = 0;
	any dt = &indent;

	bool success = pegParser->parse(text.c_str(), dt, value);

	if(success){
		cout << "parsing successful, result = " << lua_tostring(L, value.get<LuaStackPtr>().idx) << endl;
	}
	else{
		cout << "parsing failed" << endl;
	}

	return 0;
}


// main
int Main(vector<string> args)
{

	// check arguments
	if(args.size()<3){
		cout << "usage: " << args[0] << " parser.lua file" << endl
			<< "\tRead the grammar and reduction rules from parser.lua and" << endl
			<< "\tparse the given file." << endl;
		return EXIT_FAILURE;
	}

	// init lua
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);

	// load custom lua utility library
	auto result = lua_loadutils(L);
	if (result){
		cerr << "error loading lua utils";
		return EXIT_FAILURE;
	}

	// register makeParser as parser in lua
	lua_pushcfunction(L, makeParser);
    lua_setglobal(L, "parser");

	// retister parse in lua
	lua_pushcfunction(L, parse);
    lua_setglobal(L, "parse");

	// load parser script
	result = luaL_loadfile(L, args[1].c_str()) || lua_pcall(L, 0, 0, 0);
	if (result){
		cerr << "error loading \"" << args[1] << "\": " << lua_tostring(L, -1) << endl;
		return EXIT_FAILURE;
	}
/*
	// load text to parse
	ifstream textfile {args[2]};
	if(textfile.fail()){
		cerr << "error loading \"" << args[2] << "\": file not found" << endl;
		return EXIT_FAILURE;
	}
	string text { istreambuf_iterator<char>(textfile), istreambuf_iterator<char>() };
*/

	// end lua
	lua_close(L);

	return EXIT_SUCCESS;
}

int main(int c, char** v){
	int result = Main(vector<string>(v, c + v));
#ifdef _DEBUG
	system("PAUSE");
#endif
	return result;
}
