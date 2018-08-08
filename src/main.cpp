#include <iostream>
#include <fstream>
#include <string>
#include "lua/src/lua.hpp"
#include "luautils.h"
#include "stringutils.h"
#include "peglib.h"

#define DEBUG_STRLEN 40 // display that many chars of the parsing text in debug output

using namespace peg;
using namespace std;

void registerReductionRule(parser& pegParser, const string& rule, const lua::value& reduce){
	// rule = the name of the PEG definition that invoked the reduction rule (NAME <- A / B / C)
	// reduce = a lua handle of the associated reduce function

	pegParser[rule.c_str()] = [rule, reduce](const SemanticValues& sv, any&) {

		// push input parameters on stack
		const lua::value params = lua::newtable();
		params["choice"] = sv.choice();
		params["column"] = sv.line_info().second;
		params["line"] = sv.line_info().first;
		params["matched"] = StringPtr(sv.c_str(), sv.length());
		params["rule"] = rule;

		const lua::value values = lua::newtable();
		for (size_t i = 0; i != sv.size(); ++i){
			values[1 + i] = sv[i].get<lua::value>();
		}
		params["values"] = values;

		const lua::value tokens = lua::newtable();
		for (size_t i = 0; i != sv.tokens.size(); ++i) {
			tokens[1 + i] = StringPtr(sv.tokens[i].first, sv.tokens[i].second);
		}
		params["tokens"] = tokens;

		// call lua function and return lua value.
		return reduce(params);
	};
}


int parse(lua_State *L){
	lua::scope luascope(L);

	lua_pushvalue(L, 1);
	const lua::value self = lua::value::pop();

	// pointer to parser
	lua::value hparser(self["handle"]);
	parser *pegParser = (parser*) hparser.touserdata();

	// text to parse
	string text = lua_tostring(L, 2);

	// do parsing
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


int makeParser(lua_State *L){
	lua::scope luascope(L);

	lua_pushvalue(L, 1);
	const lua::value options = lua::value::pop();

	// TODO: these error checks need to be more specific and default values have to be created

	// read grammar
	lua::value grammar(options["grammar"]);
	if(grammar.isnil()){
		cerr << "no grammar defined" << endl;
		return 0;
	}

	// read default actions
	lua::value defaultReduce(options["default"]);
	if(defaultReduce.isnil()){
		cerr << "no default reduction action defined" << endl;
		return 0;
	}

	// read specific reduction actions
	lua::value actions(options["actions"]);
	if(actions.isnil()){
		cerr << "no reduction actions defined" << endl;
		return 0;
	}

	// packrat mode
	bool packrat = false;
	lua::value lvpackrat(options["packrat"]);
	if(!lvpackrat.isnil()){
		packrat = lvpackrat.toboolean();
	}

	// debug output during parsing
	bool debug = false;
	lua::value lvdebug(options["debuglog"]);
	if(!lvdebug.isnil()){
		debug = lvdebug.toboolean();
	}

	// create parser
	parser *pegParser = new parser(grammar.tostring().c_str());
	if(packrat){
		pegParser->enable_packrat_parsing();
	}

	// register actions for all PEG definitions
	const auto rules = pegParser->get_rule_names();
	for (const auto& rule : rules) {
		const lua::value reduce(actions[rule]);
		if (!reduce.isnil()) {
			registerReductionRule(*pegParser, rule, reduce);
		}
		else {
			registerReductionRule(*pegParser, rule, defaultReduce);
		}
	}

	// assign callbacks for parser debugging
	if(debug){
		for(auto& rule:rules){

			(*pegParser)[rule.c_str()].enter = [rule](const char* s, size_t n, any& dt) {
				auto& indent = *dt.get<int*>();
				cout << repeat("|  ", indent) << rule << " => \"" << shorten(s, n, DEBUG_STRLEN) << "\"?" << endl;
				indent++;
			};

			(*pegParser)[rule.c_str()].leave = [rule](const char* s, size_t, size_t matchlen, any& value, any& dt) {
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
		pegParser->log = [](size_t ln, size_t col, const string& msg) {
			cout << "(" << ln << "," << col << ") " << msg;
		};
	}

	// return parser object
	const lua::value parserObj = lua::newtable();
	parserObj["handle"] = (void*) pegParser;
	parserObj["parse"] = parse;
	parserObj.push();

	return 1;
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

	// register makeParser as pegparser in lua
	lua_pushcfunction(L.get(), makeParser);
    lua_setglobal(L.get(), "pegparser");

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
