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

#define remRefDecltype(X) std::remove_reference_t<decltype(X)>
#define addRefDecltype(X) std::add_lvalue_reference_t<decltype(X)>


// access(obj) calls obj.access()
template <typename T>
auto access(T& accessed) -> decltype(accessed.access()){
	return accessed.access();
}

// access(obj, arg1) calls obj[arg1]
template <typename T, typename Arg>
auto access(T& accessed, Arg&& arg) -> decltype(accessed[std::forward<Arg>(arg)]){
	return accessed[std::forward<Arg>(arg)];
}

// access(obj, arg1, arg2, ...) calls obj.access(arg1, arg2, ...)
template <typename T, typename ... Args>
auto access(T& accessed, Args&& ... args) -> decltype(accessed.access(std::forward<Args>(args)...)){
	return accessed.access(std::forward<Args>(args)...);
}
