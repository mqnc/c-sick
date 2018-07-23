#include <iostream>
#include <fstream>
#include <string>
#include "lua/src/lua.hpp"
#include "peglib.h"


using namespace peg;
using namespace std;


int Main(vector<string> args)
{

	// parser test:
	//-------------
	
	// create grammar
	const auto syntax = R"(
		Additive <- (Multitive AddOp)* Multitive
		AddOp <- '+' / '-'
		Multitive <- (Primary MulOp)* Primary
		MulOp <- '*' / '/'
		Primary <- '(' Additive ')'
			 / Number
		Number <- < [0-9]+ >
		%whitespace <- [ \t]*
	)";

	// create parser
	parser parser(syntax);

	if (!parser){
		cout << "error creating grammar" << endl;
		return EXIT_FAILURE;
	}

	// create callbacks for debugging
	auto rules = parser.get_rule_names();

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

	// parse string
	parser.enable_packrat_parsing();

	int val;

	int indent = 0;
	any dt = &indent;
	bool success = parser.parse(" 10 * 5 - 1 ", dt, val);
	
	if(success){
		cout << "parsing successful" << endl;
	}
	else{
		cout << "parsing failed" << endl;
	}
	
	// lua test:
	//----------
	
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	auto result = luaL_loadfile(L, "parser.lua") || lua_pcall(L, 0, 0, 0);
	if (result){
		cout << "error loading parser.lua: %s!\n", lua_tostring(L, -1);
		return EXIT_FAILURE;
	}

	lua_getglobal(L, "table1");
	if (lua_pcall(L, 0, 1, 0)){
		cout << "error calling table1(): %s!\n", lua_tostring(L, -1);
	}
	auto t1 = lua_gettop(L);
	
	lua_getglobal(L, "table2");
	if (lua_pcall(L, 0, 1, 0)){
		cout << "error calling table2(): %s!\n", lua_tostring(L, -1);
	}
	auto t2 = lua_gettop(L);
	
	lua_getglobal(L, "usetables");
	lua_pushvalue(L, t1);
	lua_pushvalue(L, t2);
	
	if (lua_pcall(L, 2, 0, 0)){
		cout << "error calling usetables(): %s!\n", lua_tostring(L, -1);
	}
	
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
