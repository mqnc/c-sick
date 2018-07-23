#include <iostream>
#include <fstream>
#include <string>
#include "lua/src/lua.hpp"
#include "peglib.h"

#define DEBUG_PARSER

using namespace peg;
using namespace std;

int Main(vector<string> args)
{

	// init lua
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);

	// load parser script
	auto result = luaL_loadfile(L, "parser.lua") || lua_pcall(L, 0, 0, 0);
	if (result){
		cout << "error loading parser.lua: %s!\n", lua_tostring(L, -1);
		return EXIT_FAILURE;
	}

	// load grammar from parser script
	lua_getglobal(L, "grammar");
	if(!lua_isstring(L, -1)){
		cout << "there is no global string variable \"grammar\" in the lua file" << endl;
		return EXIT_FAILURE;
	}
	string grammar = lua_tostring(L, -1);

	// create parser
	parser parser(grammar.c_str());
	if (!parser){
		cout << "error creating parser" << endl;
		return EXIT_FAILURE;
	}
	auto rules = parser.get_rule_names();

	// wrapper for lua function returns
	struct LuaReturn{
		string ruleName; // name of the rule that returned the value
		unsigned int stackIndex=0; // stack pointer to value
	};

	// wrapper to invoke lua functions from rules

	// look for default rule
	bool foundDefault = true;
	lua_getglobal(L, "default");
	if(!lua_isfunction(L, -1)){
		cout << "warning: no default rule found";
		foundDefault = false;
	}

	// assign in-lua-defined rules
	for(auto rule:rules){
		string funcName = rule.c_str();
		lua_getglobal(L, funcName.c_str()); // put pointer to function on stack
		if(!lua_isfunction(L, -1)){
			if(foundDefault){funcName = "default";}
			else{funcName = "";}
		}

		if(funcName != ""){
			parser[rule.c_str()] = [&L, rule, funcName](const SemanticValues& sv, any& dt){

				// find function				
				lua_getglobal(L, funcName.c_str());

				// push input parameters on stack
				lua_pushstring(L, rule.c_str()); // name of the rule
				lua_pushlstring(L, sv.c_str(), sv.length()); // matched string
				lua_pushinteger(L, sv.line_info().first); // line
				lua_pushinteger(L, sv.line_info().second); // column
				lua_pushinteger(L, sv.choice()); // choice
				lua_newtable(L); // semantic values
				for(auto& val:sv){
					lua_pushstring(L, val.get<LuaReturn>().ruleName.c_str()); // key for table indexing
					lua_pushvalue(L, val.get<LuaReturn>().stackIndex); // stack pointer to actual content
					lua_settable(L, -3); // add field to table
				}
				lua_newtable(L); // tokens
				for(int i=0; i<sv.tokens.size(); i++){
					lua_pushinteger(L, i); // key for table indexing
					lua_pushlstring(L, sv.tokens[i].first, sv.tokens[i].second); // token
					lua_settable(L, -3); // add field to table
				}

				// call function
				if (lua_pcall(L, 7, 1, 0)){
					cout << "error invoking rule: %s!\n", lua_tostring(L, -1);
				}

				// return lua value
				LuaReturn result;
				result.ruleName = rule;
				result.stackIndex = lua_gettop(L);
				return result;
			};
		}
	}

	// assign callbacks for parser debugging
	#ifdef DEBUG_PARSER
	for(auto r:rules){
		
		parser[r.c_str()].enter = [r](const char* s, size_t n, any& dt) {
			auto& indent = *dt.get<int*>();
			for(int i=0; i<indent; i++){cout << "|  ";}
			string beginning(s, n);
			if(beginning.length()>10){beginning = beginning.substr(0,10) + "...";}
			cout << r << " => \"" << beginning << "\"?" << endl;
			indent++;
		};

		parser[r.c_str()].leave = [r](const char* s, size_t n, bool match, any& dt) {
			auto& indent = *dt.get<int*>();
			indent--;
			for(int i=0; i<indent; i++){cout << "|  ";}
			if(match){cout << "`-> match" << endl;}
			else{cout << "`-> failed" << endl;}
		};
	}
	parser.log = [&](size_t ln, size_t col, const string& msg) {
		cout << "(" << ln << "," << col << ") " << msg;
	};
	#endif

	// parse string
	parser.enable_packrat_parsing();

	LuaReturn value;
	int indent = 0;
	any dt = &indent;
	bool success = parser.parse(" 10 * 5 - 1 ", dt, value);
	
	if(success){
		cout << "parsing successful" << endl;
	}
	else{
		cout << "parsing failed" << endl;
	}

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
