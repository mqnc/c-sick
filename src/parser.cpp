
#include "parser.h"

#include <iostream>
#include <memory>
#include <string>
#include "lua/src/lua.hpp"
#include "peglib.h"

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
		// 0-based c++ indices are converted to 1-based lua indices
		const lua::value params = lua::newtable();
		params["choice"] = sv.choice() + 1;
		//params["line"] = sv.line_info().first;
		//params["column"] = sv.line_info().second;
		//params["matched"] = StringPtr(sv.c_str(), sv.length());
		params["pos"] = (int)(sv.c_str() - sv.ss) + 1;
		params["len"] = sv.length();
		params["rule"] = rule;

		const lua::value values = lua::newtable();
		for (size_t i = 0; i != sv.size(); ++i){
			values[i+1] = sv[i].get<lua::value>();
		}
		params["values"] = values;

		const lua::value tokens = lua::newtable();
		for (size_t i = 0; i != sv.tokens.size(); ++i) {
			tokens[i+1] = StringPtr(sv.tokens[i].first, sv.tokens[i].second);
		}
		params["tokens"] = tokens;

		// call lua function
		auto result = reduce(params);

		// include additional information
		if(result.type() == LUA_TTABLE){
			result["pos"] = (int)(sv.c_str() - sv.ss) + 1;
			result["len"] = sv.length();
			result["rule"] = rule;
		}

		return result;
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
		//cout << "parsing successful, result = " << value.get<lua::value>().tostring() << endl;
		//cout << "parsing successful" << endl;
		return value.get<lua::value>();
	}
	else{
		cout << "parsing failed" << endl;
		return lua::value(); // return nil
	}
}

pegparser::pegparser() {
	const lua::value options = lua::value::at(1);

	// TODO: these error checks need to be more specific and default values have to be created

	// read grammar
	lua::value grammar(options["grammar"]);
	if(grammar.isnil()){
		lua::error("no grammar defined");
		return;
	}

	// read default actions
	lua::value defaultReduce(options["default"]);
	if(defaultReduce.isnil()){
		lua::error("no default reduction action defined");
		return;
	}

	// read specific reduction actions
	lua::value actions(options["actions"]);
	if(actions.isnil()){
		lua::error("no reduction actions defined");
		return;
	}

	// packrat mode
	bool packrat = true;
	lua::value lvpackrat(options["packrat"]);
	if(!lvpackrat.isnil()){
		packrat = lvpackrat.toboolean();
	}

	// create parser
	m_parser = std::make_unique<parser>();
    m_parser->log = [](size_t line, size_t col, const string& msg) {
        cerr << line << ":" << col << ": " << msg << "\n";
    };
    auto ok = m_parser->load_grammar(grammar.tocstring());
    if(!ok){
		cerr << "error loading grammar\n";
		return;
	}
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
}

#ifndef _MSC_VER
constexpr
#else
extern const
#endif
	char pegparser_name[] = "pegparser";
using pegparser_metatable = lua::metatable<pegparser_name, pegparser>;

constexpr lua::method pegparser_methods[] = {
	{ "parse", pegparser_metatable::mem_fn<&pegparser::parse> },
};

lua::value makeParser() {
	return pegparser_metatable::newuserdata(pegparser_methods);
}
