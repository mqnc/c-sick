#include <iostream>
#include <fstream>
#include <string>
#include "lua/src/lua.hpp"
#include "luautils.h"
#include "stringutils.h"
#include "peglib.h"

#define DEBUG_PARSER

using namespace peg;
using namespace std;

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
	
	// load parser script
	result = luaL_loadfile(L, args[1].c_str()) || lua_pcall(L, 0, 0, 0);
	if (result){
		cerr << "error loading \"" << args[1] << "\": " << lua_tostring(L, -1) << endl;
		return EXIT_FAILURE;
	}

	// load text to parse
	ifstream textfile {args[2]};
	if(textfile.fail()){
		cerr << "error loading \"" << args[2] << "\": file not found" << endl;
		return EXIT_FAILURE;
    }
	string text { istreambuf_iterator<char>(textfile), istreambuf_iterator<char>() };	

	// copy grammar from parser script
	lua_getglobal(L, "grammar");
	if(!lua_isstring(L, -1)){
		cerr << "error parsing grammar: there is no global string variable \"grammar\" in the lua file" << endl;
		return EXIT_FAILURE;
	}
	string grammar = lua_tostring(L, -1);

	// create parser
	parser parser(grammar.c_str());
	if (!parser){
		cerr << "error creating parser" << endl;
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
	for(const auto& rule:rules){
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
					lua_pushfield(L, "rule",    rule);
					lua_pushfield(L, "matched", StringPtr(sv.c_str(), sv.length()));
					lua_pushfield(L, "line",    sv.line_info().first);
					lua_pushfield(L, "column",  sv.line_info().second);
					lua_pushfield(L, "choice",  sv.choice());

					lua_opensubtable(L, "subnodes"); 
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
		else{ // function not found, no default function in lua script -> just return last matched token
			parser[rule.c_str()] = [&L, rule](const SemanticValues& sv, any& dt){

				if(sv.tokens.size() == 0){
					lua_push(L, StringPtr(sv.c_str(), sv.length())); // no tokens, return matched string
				}
				else{
					lua_push(L, StringPtr(sv.tokens.back().first, sv.tokens.back().second)); // return last token
				}

				// return lua value
				return LuaStackPtr(lua_gettop(L));
			};
		}
	}

	// assign callbacks for parser debugging
	#ifdef DEBUG_PARSER
	for(auto r:rules){
		
		parser[r.c_str()].enter = [r](const char* s, size_t n, any& dt) {
			auto& indent = *dt.get<int*>();
			cout << repeat("|  ", indent) << r << " => \"" << shorten(string(s, n), 40) << "\"?" << endl;
			indent++;
		};

		parser[r.c_str()].leave = [r, &L](const char* s, size_t n, size_t matchlen, any& value, any& dt) {
			auto& indent = *dt.get<int*>();
			indent--;
			cout << repeat("|  ", indent) << "`-> ";
			if(success(matchlen)){

				// display "match", the matched string and the result of the reduction
				cout << "match: \"" << shorten(string(s, matchlen), 40) << "\" -> ";
				lua_getglobal(L, "stringify");
				lua_push(L, value.get<LuaStackPtr>());
				lua_pcall(L, 1, 1, 0);
				string output = lua_tostring(L, -1);
				cout << shorten(output, 40) << endl;
			}
			else{
				cout << "failed" << endl;
			}
		};
	}
	parser.log = [&](size_t ln, size_t col, const string& msg) {
		cout << "(" << ln << "," << col << ") " << msg;
	};
	#endif

	// parse string
	parser.enable_packrat_parsing();

	any value;
	int indent = 0;
	any dt = &indent;

	bool success = parser.parse(text.c_str(), dt, value);
	
	if(success){
		cout << "parsing successful, result = " << lua_tostring(L, value.get<LuaStackPtr>().idx) << endl;
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

