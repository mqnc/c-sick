
#include "parser.h"

#include <iostream>
#include <memory>
#include <string>
#include "lua/src/lua.hpp"
#include "stringutils.h"
#include "peglib.h"

#define DEBUG_STRLEN 40 // display that many chars of the parsing text in debug output

using namespace peg;
using namespace std;

namespace {
	class pegparser {
	public:
		pegparser();

		lua::value parse();

	private:
		std::unique_ptr<parser> m_parser;
	};
}

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


lua::value pegparser::parse() {
	// text to parse
	const char* const text = lua_tostring(lua::scope::state(), 2);

	// do parsing
	any value;
	int indent = 0;
	any dt = &indent;

	bool success = m_parser->parse(text, dt, value);

	if(success){
		cout << "parsing successful, result = " << value.get<lua::value>().tostring() << endl;
	}
	else{
		cout << "parsing failed" << endl;
	}

	return value.get<lua::value>();
}

pegparser::pegparser() {
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
	m_parser = std::make_unique<parser>(grammar.tocstring());
	if (packrat) {
		m_parser->enable_packrat_parsing();
	}

	// register actions for all PEG definitions
	const auto rules = m_parser->get_rule_names();
	for (const auto& rule : rules) {
		const lua::value reduce(actions[rule]);
		if (!reduce.isnil()) {
			registerReductionRule(*m_parser, rule, reduce);
		}
		else {
			registerReductionRule(*m_parser, rule, defaultReduce);
		}
	}

	// assign callbacks for parser debugging
	if(debug){
		for(auto& rule:rules){

			(*m_parser)[rule.c_str()].enter = [rule](const char* s, size_t n, any& dt) {
				auto& indent = *dt.get<int*>();
				cout << repeat("|  ", indent) << rule << " => \"" << shorten(s, n, DEBUG_STRLEN) << "\"?" << endl;
				indent++;
			};

			(*m_parser)[rule.c_str()].leave = [rule](const char* s, size_t, size_t matchlen, any& value, any& dt) {
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
		m_parser->log = [](size_t ln, size_t col, const string& msg) {
			cout << "(" << ln << "," << col << ") " << msg;
		};
	}
}

//constexpr char pegparser_name[] = "pegparser";
char pegparser_name[] = "pegparser";
using pegparser_metatable = lua::metatable<pegparser_name, pegparser>;

constexpr lua::method pegparser_methods[] = {
	{ "parse", pegparser_metatable::mem_fn<&pegparser::parse> },
};

lua::value makeParser() {
	return pegparser_metatable::newuserdata(pegparser_methods);
}
