#include <iomanip>
#include <iostream>
#include <string>
#include <sstream>

// feed one argument to a stream using <<
template<typename T, typename... Args>
void feed(std::ostream& os, const T &arg){
	os << arg;
}

// feed an arbitrary number of arguments to a stream
template<typename T, typename... Args>
void feed(std::ostream& os, const T &arg, const Args... args){
	feed(os, arg);
	feed(os, args...);
}

// fill a string
template<typename... Args>
std::string concat(const Args... args){
	std::stringstream ss;
	feed(ss, args...);
	return ss.str();
}

// print to cout and break line
template<typename... Args>
void print(const Args... args){
	feed(std::cout, args...);
	std::cout << std::endl;
}
