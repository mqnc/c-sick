#include <iostream>
#include <fstream>
#include <string>
#include "lua/src/lua.hpp"
#include "luautils.h"
#include "stringutils.h"
#include "peglib.h"

#define DEBUG_PARSER
#define DEBUG_STRLEN 40 // display that many chars of the parsing text in debug output

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

	// load parser script
	result = luaL_loadfile(L.get(), args[1].c_str()) || lua_pcall(L.get(), 0, 0, 0);
	if (result){
		cerr << "error loading \"" << args[1] << "\": " << lua_tostring(L.get(), -1) << endl;
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
	lua_getglobal(L.get(), "grammar");
	if(!lua_isstring(L.get(), -1)){
		cerr << "error parsing grammar: there is no global string variable \"grammar\" in the lua file" << endl;
		return EXIT_FAILURE;
	}
	string grammar = lua_tostring(L.get(), -1);

	// create parser
	parser parser(grammar.c_str());
	if (!parser){
		cerr << "error creating parser" << endl;
		return EXIT_FAILURE;
	}
	auto rules = parser.get_rule_names();

	// look for default rule in lua parser script
	bool foundDefault = true;
	lua_getglobal(L.get(), "default");
	if(!lua_isfunction(L.get(), -1)){
		foundDefault = false;
	}

	// assign in-lua-defined rules
	for(const auto& rule:rules){
		string funcName = rule.c_str();
		lua_getglobal(L.get(), funcName.c_str()); // put pointer to function on stack
		if(!lua_isfunction(L.get(), -1)){
			if(foundDefault){funcName = "default";}
			else{funcName = "";}
		}

		if(funcName != ""){ // use the specified function or the default function from the lua script
			parser[rule.c_str()] = [rule, funcName](const SemanticValues& sv, any&){

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
		else{ // function not found, no default function in lua script -> just return last matched token
			parser[rule.c_str()] = [&L](const SemanticValues& sv, any&){
				if(sv.tokens.size() == 0){
					lua_pushlstring(L.get(), sv.c_str(), sv.length()); // no tokens, return matched string
				}
				else {
					lua_pushlstring(L.get(), sv.tokens.back().first, sv.tokens.back().second); // return last token
				}

				// return lua value
				return lua::value();
			};
		}
	}

	// assign callbacks for parser debugging
	#ifdef DEBUG_PARSER
	for(auto r:rules){

		parser[r.c_str()].enter = [r](const char* s, size_t n, any& dt) {
			auto& indent = *dt.get<int*>();
			cout << repeat("|  ", indent) << r << " => \"" << shorten(s, n, DEBUG_STRLEN) << "\"?" << endl;
			indent++;
		};

		parser[r.c_str()].leave = [r](const char* s, size_t, size_t matchlen, any& value, any& dt) {
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
		cout << "parsing successful, result = " << value.get<lua::value>().tostring() << endl;
	}
	else{
		cout << "parsing failed" << endl;
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
