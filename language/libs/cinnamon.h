#include <iomanip>
#include <iostream>
#include <string>
#include <sstream>

#include "range.hpp"

// feed no arguments to a stream
void feed__(std::ostream& os){
	(void) os;
}

// feed one argument to a stream using <<
template<typename T, typename... Args>
void feed__(std::ostream& os, const T &arg){
	os << arg;
}

// feed an arbitrary number of arguments to a stream
template<typename T, typename... Args>
void feed__(std::ostream& os, const T &arg, const Args... args){
	feed__(os, arg);
	feed__(os, args...);
}

// fill a string
template<typename... Args>
std::string concat(const Args... args){
	std::stringstream ss;
	feed__(ss, args...);
	return ss.str();
}

// print to cout
template<typename... Args>
void print(const Args... args){
	feed__(std::cout, args...);
}

// print to cout and break line
template<typename... Args>
void println(const Args... args){
	print(args...);
	std::cout << std::endl;
}

const double inf = std::numeric_limits<double>::infinity();

#define remRefDecltype(X) typename std::remove_reference<decltype(X)>::type
