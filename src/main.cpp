#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <memory>
#include "lua/src/lua.hpp"
#include "luautils.h"
#include "parser.h"

lua_State* lua::scope::s_L = nullptr;

using namespace std;

// main
int Main(vector<string> args)
{

	// check arguments
	if(args.size()<2){
		cout << "usage: " << args[0] << " file.lua" << endl;
		return EXIT_FAILURE;
	}

	// init lua
	// Since the parser state holds Lua values, it's important that the Lua VM and lua::scope
	// remain until after the parser is destroyed. Using a unique_ptr ensures that Lua outlives
	// any variables created later in this function.
	std::unique_ptr<lua_State, void(&)(lua_State*)> L(luaL_newstate(), lua_close);
	lua::scope luascope(L.get());
	luaL_openlibs(L.get());

	// register makeParser as pegparser in lua
	lua::globals()["pegparser"] = lua::invoke<makeParser>;

	// load parser script
	auto result = luaL_loadfile(L.get(), args[1].c_str()) || lua_pcall(L.get(), 0, 0, 0);
	if (result){
		cerr << "error loading \"" << args[1] << "\": " << lua_tostring(L.get(), -1) << endl;
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}

int main(int c, char** v){
	int result = Main(vector<string>(v, c + v));
#ifdef _DEBUG
	system("PAUSE");
#endif
	return result;
}
