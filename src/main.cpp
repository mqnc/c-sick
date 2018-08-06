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

		// push input parameters on stack
		const lua::value params = lua::newtable();
		params["choice"] = sv.choice();
		params["column"] = sv.line_info().second;
		params["line"] = sv.line_info().first;
		params["matched"] = StringPtr(sv.c_str(), sv.length());
		params["rule"] = rule;

		const lua::value subnodes = lua::newtable();
		for (size_t i = 0; i != sv.size(); ++i){
			subnodes[1 + i] = sv[i].get<lua::value>();
		}
		params["subnodes"] = subnodes;

		const lua::value tokens = lua::newtable();
		for (size_t i = 0; i != sv.tokens.size(); ++i) {
			tokens[1 + i] = StringPtr(sv.tokens[i].first, sv.tokens[i].second);
		}
		params["tokens"] = tokens;

		// find function
		const lua::value func(lua::globals()[funcName.c_str()]);

		// call lua function and return lua value.
		return func(params);
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
				const lua::value stringify(lua::globals()["stringify"]);
				const string output = stringify(value.get<lua::value>()).tostring();
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
		cout << "parsing successful, result = " << value.get<lua::value>().tostring() << endl;
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
	// Since the parser state holds Lua values, it's important that the Lua VM and lua::scope
	// remain until after the parser is destroyed. Using a unique_ptr ensures that Lua outlives
	// any variables created later in this function.
	std::unique_ptr<lua_State, void(&)(lua_State*)> L(luaL_newstate(), lua_close);
	lua::scope luascope(L.get());
	luaL_openlibs(L.get());

	// load custom lua utility library
	auto result = lua_loadutils(L.get());
	if (result){
		cerr << "error loading lua utils";
		return EXIT_FAILURE;
	}

	// register makeParser as parser in lua
	lua_pushcfunction(L.get(), makeParser);
    lua_setglobal(L.get(), "parser");

	// retister parse in lua
	lua_pushcfunction(L.get(), parse);
    lua_setglobal(L.get(), "parse");

	// load parser script
	result = luaL_loadfile(L.get(), args[1].c_str()) || lua_pcall(L.get(), 0, 0, 0);
	if (result){
		cerr << "error loading \"" << args[1] << "\": " << lua_tostring(L.get(), -1) << endl;
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

	return EXIT_SUCCESS;
}

int main(int c, char** v){
	int result = Main(vector<string>(v, c + v));
#ifdef _DEBUG
	system("PAUSE");
#endif
	return result;
}