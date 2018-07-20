
#include "peglib.h"

using namespace peg;
using namespace std;

#define RULE(name) parser[#name] = [](const SemanticValues& sv)
#define SV(I) sv[I].get<string>()

int prio = 0;

int main (int argc, char *argv[])
{ 
	string grammar = R"(
		start <- (same / hi / inc / operator / tab / char)*
		same <- 'SAME'
		hi <- 'HI'
		inc <- 'INC\n'
		operator <- 'OPERATOR'
		tab <- '\t'
		char <- .
	)";
	
	parser parser(grammar.c_str());
	
	if (!parser) {
		cout << "error parsing grammar";
		string line;
		getline(cin, line);
		return EXIT_FAILURE;
	}
	
	string opgrammar = R"(
		OpKw <- 'operator'
		SAME <- Identifier / '(' Expression ')'
		INC
		SAME <- HI '::' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '++' / HI '--' / HI '(' Expression ')' / HI '[' Expression ']' / HI '.' SAME / HI OPERATOR / HI
		INC
		SAME <- '++' HI / '--' HI / '+' HI / '-' HI / '!' HI / '~' HI / '(' Expression ')' HI / '*' HI / '&' HI / OPERATOR HI / HI
		INC
		SAME <- HI '.*' SAME / HI '->*' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '*' SAME / HI '/' SAME / HI '%' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '+' SAME / HI '-' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '<<' SAME / HI '>>' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '<' SAME / HI '<=' SAME / HI '>' SAME / HI '>=' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '==' SAME / HI '!=' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '&' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '^' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '|' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '&&' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '||' SAME / HI OPERATOR SAME / HI
		INC
		SAME <- HI '?' HI ':' HI / SAME ':=' HI / SAME '+=' HI / SAME '-=' HI / SAME '*=' HI / SAME '/=' HI / SAME '%=' HI / SAME '<<=' HI / SAME '>>=' HI / SAME '&=' HI / SAME '^=' HI / SAME '|=' HI / SAME OPERATOR HI / HI
		Expression <- SAME
		OpName <- Identifier
	)";
	

	RULE(char){cout << sv.str();};
	RULE(inc){prio++;};
	RULE(same){cout << "Prio" << prio;};
	RULE(hi){cout << "Prio" << prio-1;};
	RULE(operator){cout << "OpKw '" << prio << "(' OpName ')'";};

	parser.enable_packrat_parsing();
		
	string val;

	parser.parse(opgrammar.c_str(), val);	

	string line;
	getline(cin, line);
	return EXIT_SUCCESS;
}














