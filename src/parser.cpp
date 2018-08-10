
#include "parser.h"

#include <iostream>
#include <string>
#include "lua/src/lua.hpp"
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


lua::value parse() {
	// pointer to parser
	parser *pegParser = static_cast<parser*>(luaL_checkudata(lua::scope::state(), 1, "pegparser"));

	// text to parse
	const char* const text = lua_tostring(lua::scope::state(), 2);

	// do parsing
	any value;
	int indent = 0;
	any dt = &indent;

	bool success = pegParser->parse(text, dt, value);

	if(success){
		cout << "parsing successful, result = " << value.get<lua::value>().tostring() << endl;
	}
	else{
		cout << "parsing failed" << endl;
	}

	return value.get<lua::value>();
}

lua::value destroyParser() {
	// pointer to parser
	parser *pegParser = static_cast<parser*>(luaL_checkudata(lua::scope::state(), 1, "pegparser"));
	pegParser->~parser();

	return lua::value();
}

lua::value makeParser() {
	const lua::value options = lua::value::at(1);

	// TODO: these error checks need to be more specific and default values have to be created

	// read grammar
	lua::value grammar(options["grammar"]);
	if(grammar.isnil()){
		lua::error("no grammar defined");
	}

	// read default actions
	lua::value defaultReduce(options["default"]);
	if(defaultReduce.isnil()){
		lua::error("no default reduction action defined");
	}

	// read specific reduction actions
	lua::value actions(options["actions"]);
	if(actions.isnil()){
		lua::error("no reduction actions defined");
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
	parser *pegParser = static_cast<parser*>(lua_newuserdata(lua::scope::state(), sizeof(parser)));
	new (pegParser) parser(grammar.tocstring());
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

	// Create pegparser metatable.
	if (luaL_newmetatable(lua::scope::state(), "pegparser")) {
		const lua::value indextable = lua::newtable();
		indextable["parse"] = lua::invoke<parse>;

		const lua::value metatable = lua::value::at(-1);
		metatable["__gc"] = lua::invoke<destroyParser>;
		metatable["__index"] = indextable;
	}
	lua_setmetatable(lua::scope::state(), -2);

	// return parser object
	return lua::value::pop();
}
