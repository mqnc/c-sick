
#pragma once
#include "peglib.h"

using namespace peg;
using namespace std;

auto concat = [](const SemanticValues& sv) {
	string result;

	// if there are tokens, concat the tokens
	if (sv.tokens.size() > 0) {
		for (auto t : sv.tokens) {
			result += string(t.first, t.second);
		}
		return result;
	}

	// if there are semantic values, concat them
	if (sv.size() > 0) {
		for (auto s : sv) {
			result += s.get<string>();
		}
		return result;
	}
	
	// just return the captured string
	return sv.str();
};

class customparser // almost identical to parser, just the members are public and it works with std::strings
{
public:
    customparser() = default;

    customparser(const string s) {
        m_grammar = ParserGenerator::parse(s.c_str(), s.length(), m_start, log);

		// default action is to concat tokens, else all semvals, else just the captured string
		for (auto rule = m_grammar->begin(); rule != m_grammar->end(); rule++) {
			const auto rulename = rule->first.c_str();

			
			(*m_grammar)[rulename].enter = [rulename](string s, any& dt) {
				auto& indent = *dt.get<int*>();
				for (int i = 0; i < indent; i++) { cout << "|  "; }
				//cout << "Does \"" << s << "\" start with " << rulename << "?" << endl;
				cout << rulename << " starts \"" << s << "\"?" << endl;
				indent++;
			};

			(*m_grammar)[rulename].leave = [rulename](string s, bool match, any& dt) {
				auto& indent = *dt.get<int*>();
				indent--;
				for (int i = 0; i < indent; i++) { cout << "|  "; }
				//if (match) { cout << "\"" << s << "\" starts with " << rulename << "!" << endl; }
				//else       { cout << "\"" << s << "\" doesnt start with " << rulename << "!" << endl; }
				if (match) { cout << "`-> yes!" << endl; }
				else       { cout << "`-> no!" << endl; }
			};

			(*m_grammar)[rulename] = concat;
		}
    }

    operator bool() {
        return m_grammar != nullptr;
    }

    template <typename T>
    bool parse(const string s, T& val, const char* path = nullptr) const {
		int indent = 0;
		any dt = &indent;

        if (m_grammar != nullptr) {
            const auto& rule = (*m_grammar)[m_start];
            auto r = rule.parse_and_get_value(s.c_str(), s.length(), dt, val, path);
            output_log(s.c_str(), s.length(), r);
            return r.ret && r.len == s.length();
        }
        return false;
    }

    template <typename T>
    bool parse(const string s, any& dt, T& val, const char* path = nullptr) const {
        if (m_grammar != nullptr) {
            const auto& rule = (*m_grammar)[m_start];
            auto r = rule.parse_and_get_value(s.c_str(), s.length(), dt, val, path);
            output_log(s.c_str(), s.length(), r);
            return r.ret && r.len == s.length();
        }
        return false;
    }

    bool search(const char* s, size_t n, size_t& mpos, size_t& mlen) const {
        const auto& rule = (*m_grammar)[m_start];
        if (m_grammar != nullptr) {
            size_t pos = 0;
            while (pos < n) {
                size_t len = n - pos;
                auto r = rule.parse(s + pos, len);
                if (r.ret) {
                    mpos = pos;
                    mlen = len;
                    return true;
                }
                pos++;
            }
        }
        mpos = 0;
        mlen = 0;
        return false;
    }

    bool search(const char* s, size_t& mpos, size_t& mlen) const {
        auto n = strlen(s);
        return search(s, n, mpos, mlen);
    }

    Definition& operator[](const char* s) {
        return (*m_grammar)[s];
    }

    void enable_packrat_parsing() {
        if (m_grammar != nullptr) {
            auto& rule = (*m_grammar)[m_start];
            rule.enablePackratParsing = true;
        }
    }

    template <typename T = Ast>
    customparser& enable_ast() {
        for (auto& x: *m_grammar) {
            const auto& name = x.first;
            auto& rule = x.second;

            if (!rule.action) {
                auto is_token = rule.is_token;
                rule.action = [=](const SemanticValues& sv) {
                    auto line = line_info(sv.ss, sv.c_str());

                    if (is_token) {
                        return std::make_shared<T>(sv.path, line.first, line.second, name.c_str(), sv.token());
                    }

                    auto ast = std::make_shared<T>(sv.path, line.first, line.second, name.c_str(), sv.transform<std::shared_ptr<T>>());

                    for (auto node: ast->nodes) {
                        node->parent = ast;
                    }
                    return ast;
                };
            }
        }
        return *this;
    }

    void enable_trace(Tracer tracer) {
        if (m_grammar != nullptr) {
            auto& rule = (*m_grammar)[m_start];
            rule.tracer = tracer;
        }
    }

    Log log;

    void output_log(const char* s, size_t n, const Definition::Result& r) const {
        if (log) {
            if (!r.ret) {
                if (r.message_pos) {
                    auto line = line_info(s, r.message_pos);
                    log(line.first, line.second, r.message);
                } else {
                    auto line = line_info(s, r.error_pos);
                    log(line.first, line.second, "syntax error");
                }
            } else if (r.len != n) {
                auto line = line_info(s, s + r.len);
                log(line.first, line.second, "syntax error");
            }
        }
    }

    std::shared_ptr<Grammar> m_grammar;
    std::string              m_start;
};