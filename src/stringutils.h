
#pragma once

#include <ostream>
#include <string>

// helper for repeating output
struct repeat{
	repeat(const char* s_, size_t num_):s(s_), num(num_){}
	const char* s;
	size_t num;
};

inline std::ostream& operator <<(std::ostream& stream, const repeat& rep) {
	for(int i=0; i<rep.num; ++i){
		stream << rep.s;
	}
	return stream;
}

// shorten string and remove line breaks and tabs
inline std::string shorten(const char* s, std::size_t len, std::size_t maxlen) {
	std::string result(s, len<maxlen?len:maxlen);

	// shorten
	if(len>maxlen-3){
		result[maxlen-3] = result[maxlen-2] = result[maxlen-1] = '.';
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
