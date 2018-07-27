
#pragma once

#include <iostream>
#include <string>

// helper for repeating output
struct repeat{
	repeat(const char* s_, size_t num_):s(s_), num(num_){}
	const char* s;
	size_t num;
};
ostream& operator<< (ostream& stream, const repeat rep){
	for(int i=0; i<rep.num; ++i){
		stream << rep.s;
	}
	return stream;
}

// shorten string and remove line breaks and tabs
string shorten(const string& txt, const size_t numchars){
	string result = txt;

	// shorten
	if(result.length()>numchars-3){
		result = result.substr(0,numchars-3) + "...";
	}
	// replace line breaks and tabs
	for(auto& c:result){
		if(c == '\n'){
			c = '\\';
		}
		else if(c == '\t'){
			c = ' ';
		}
	}

	return result;
}
