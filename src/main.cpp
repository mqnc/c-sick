#include <iostream>
#include <fstream>
#include <string>
#include "lua/src/lua.hpp"
#include "peglib.h"

#define DEBUG_PARSER

using namespace peg;
using namespace std;

// utilities for lua stack manipulation
struct LuaStackPtr{
	string varName;
	int stackIndex=0;
};

void lua_push(lua_State *L, const int value) {lua_pushinteger(L, value);}
void lua_push(lua_State *L, const string value) {lua_pushstring(L, value.c_str());}
void lua_push(lua_State *L, const char *value) {lua_pushstring(L, value);}
void lua_push(lua_State *L, const char *value, size_t len) {lua_pushlstring(L, value, len);}
void lua_closefield(lua_State *L){ lua_settable(L, -3); }

template<typename TKey, typename TVal>
void lua_pushfield(lua_State *L, TKey key, TVal value){
	lua_push(L, key);
	lua_push(L, value);
	lua_closefield(L);
}

template<typename TKey>
void lua_pushfield(lua_State *L, TKey key, const char *value, size_t len){
	lua_push(L, key);
	lua_pushlstring(L, value, len);
	lua_closefield(L);
}

void lua_pushfield(lua_State *L, LuaStackPtr ptr){
	lua_push(L, ptr.varName);
	lua_pushvalue(L, ptr.stackIndex);
	lua_closefield(L);
}

template<typename TKey>
void lua_opensubtable(lua_State *L, TKey key){
	lua_push(L, key);
	lua_newtable(L);
}

// main
int Main(vector<string> args)
{

	// init lua
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);

	// load parser script
	auto result = luaL_loadfile(L, "parser.lua") || lua_pcall(L, 0, 0, 0);
	if (result){
		cout << "error loading parser.lua: " << lua_tostring(L, -1) << endl;
		return EXIT_FAILURE;
	}

	// copy grammar from parser script
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

	// look for default rule in lua parser script
	bool foundDefault = true;
	lua_getglobal(L, "default");
	if(!lua_isfunction(L, -1)){
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

		if(funcName != ""){ // use the specified function or the default function from the lua script
			parser[rule.c_str()] = [&L, rule, funcName](const SemanticValues& sv, any& dt){

				// find function				
				lua_getglobal(L, funcName.c_str());

				// push input parameters on stack
				lua_newtable(L);
					lua_pushfield(L, "rule", rule.c_str());
					lua_pushfield(L, "matched", sv.c_str(), sv.length());
					lua_pushfield(L, "line", sv.line_info().first);
					lua_pushfield(L, "column", sv.line_info().second);
					lua_pushfield(L, "choice", sv.choice());

					lua_opensubtable(L, "subnodes"); 
					for (size_t i = 0; i != sv.size(); ++i) {
						lua_push(L, 1 + i);
						lua_pushvalue(L, sv[i].get<LuaStackPtr>().stackIndex);
						lua_closefield(L);
					}
					lua_closefield(L);

					lua_opensubtable(L, "tokens"); 
					for (size_t i = 0; i != sv.tokens.size(); ++i) {
						lua_pushfield(L, 1 + i, sv.tokens[i].first, sv.tokens[i].second);
					}
					lua_closefield(L);

				// call lua function
				if (lua_pcall(L, 1, 1, 0)){
					cout << "error invoking rule: " << lua_tostring(L, -1) << endl;
				}

				// return lua value
				LuaStackPtr result;
				result.varName = rule;
				result.stackIndex = lua_gettop(L);
				return result;
			};
		}
		else{ // function not found, no default function in lua script -> just return last matched token
			parser[rule.c_str()] = [&L, rule](const SemanticValues& sv, any& dt){

				// return lua value
				LuaStackPtr result;
				result.varName = rule;

				if(sv.tokens.size() == 0){
					lua_push(L, sv.c_str(), sv.length()); // no tokens, return matched string
					result.stackIndex = lua_gettop(L);
				}
				else{
					lua_push(L, sv.tokens.back().first, sv.tokens.back().second); // return last token
					result.stackIndex = lua_gettop(L);
				}
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

	LuaStackPtr value;
	int indent = 0;
	any dt = &indent;
	bool success = parser.parse(" 10 * 5 - 1 ", dt, value);
	
	if(success){
		cout << "parsing successful, result = " << lua_tostring(L, value.stackIndex) << endl;
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
