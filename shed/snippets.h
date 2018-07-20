

#define READFILE(STR, FILE) {ifstream ifs(FILE); STR.assign( (istreambuf_iterator<char>(ifs) ), (istreambuf_iterator<char>()));}
#define RULE(name) testparser[#name] = [](const SemanticValues& sv)
#define SV(I) sv[I].get<string>()
#define OPTIONS switch (sv.choice())



void lua_pushentry(lua_State* L, string key, string value) {
    lua_pushstring(L, key.c_str());
    lua_pushstring(L, value.c_str());
    lua_settable(L, -3);
}

void lua_pushentry(lua_State* L, string key, int value) {
    lua_pushstring(L, key.c_str());
    lua_pushinteger(L, value);
    lua_settable(L, -3);
}

void lua_pushentry(lua_State* L, int key, string value) {
    lua_pushinteger(L, key);
    lua_pushstring(L, value.c_str());
    lua_settable(L, -3);
}






	string grammar = makeGrammar();
	customparser parser(grammar);

	if (!parser) {
		cout << "error parsing grammar";
		string line;
		getline(cin, line);
		return EXIT_FAILURE;
	}

	parser.enable_packrat_parsing();

	// create custom actions
	makeRules(parser);
		
	string val;
	//cout << parser.parse(R"($$)", val) << endl << endl;
	string src = test();
	cout << src << endl << endl;
	auto result = parser.parse(src, val);
	if (result) { cout << "################### SUCCESS!!! ################" << endl; }
	else        { cout << "################### FAILURE!!! ################" << endl; }
	cout << val << endl << endl << endl;
	





	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	auto result = luaL_loadfile(L, "parser.lua") || lua_pcall(L, 0, 0, 0);

	if (result){
		cout << "error loading parser.lua: " << lua_tostring(L, -1);
		return EXIT_FAILURE;
	}

	lua_getglobal(L, "grammar");
	if(!lua_isstring(L, 1)){
		cout << "no grammar string found!" << endl;
		return EXIT_FAILURE;
	}
	
	
		
	lua_close(L);
	
	
	
			lua_getglobal(L, rulename);
		if(lua_isfunction(L)){
			parser[rulename] = [](const SemanticValues& sv, any& dt) {
				std::cout << "yeah ABC" << std::endl;
				return sv[0].get<string>() + sv[1].get<string>() + sv[2].get<string>();
			};
		}
		
		
		
		
		
		
		
	customparser testparser(R"(
		prio4 <- prio3 '+' prio4 / prio3 '-' prio4 / prio3
		prio3 <- prio2 '*' prio3 / prio2 '/' prio3 / prio2
		prio2 <- prio15 '^' prio2 / prio15
		prio15 <- '+' prio1 / '-' prio1 / prio1
		prio1 <- '(' prio4 ')' / prio0
		prio0 <- [a-z]
	)");
	
	testparser.enable_packrat_parsing();

	RULE(prio1) {OPTIONS{
		case 0:	return SV(0); // "(" + SV(0) + ")";
		case 1:	return SV(0);
	}};

	RULE(prio15) {OPTIONS{
		case 0:	return "pos(" + SV(0) + ")";
		case 1:	return "neg(" + SV(0) + ")";
		case 2: return SV(0);
	}};

	RULE(prio2) {OPTIONS{
		case 0:	return "pow(" + SV(0) + "," + SV(1) + ")";
		case 1:	return SV(0);
	}};

	RULE(prio3) {OPTIONS{
		case 0:	return "mul(" + SV(0) + "," + SV(1) + ")";
		case 1:	return "div(" + SV(0) + "," + SV(1) + ")";
		case 2:	return SV(0);
	}};

	RULE(prio4) {OPTIONS{
		case 0:	return "add(" + SV(0) + "," + SV(1) + ")";
		case 1:	return "sub(" + SV(0) + "," + SV(1) + ")";
		case 2:	return SV(0);
	}};		
		
	string ret;
	bool ok = testparser.parse(R"(a+b+c)", ret);
	cout << "testresult: " << ok << endl << ret << endl << endl;
		
		
		
		
		
		
		
		
		