#include <iomanip>
#include <iostream>
#include <string>
#include <sstream>

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

// print to cout and break line
template<typename... Args>
void print(const Args... args){
	feed__(std::cout, args...);
	std::cout << std::endl;
}

// range placeholders
enum class RangeOpenness{CLOSED, OPEN};
enum class RangeIncOp{ADD, SUB, MUL, DIV};

template<typename T, typename TS>
class Range{
public:
	Range(RangeOpenness openStart, T start, RangeIncOp op, TS step, RangeOpenness openEnd, T end):m_start(start){
		(void) openStart; (void) op; (void) step; (void) openEnd; (void) end;
	}
	Range(RangeOpenness openStart, T start, RangeIncOp op, TS step):m_start(start){ // infinite range
		(void) openStart; (void) op; (void) step;
	}
	void popFront(){}
	T& front(){return m_start;}
	bool empty(){return true;}
private:
	T m_start;
};

const double inf = std::numeric_limits<double>::infinity();

int Int(){return 0;}

std::string String(){return "";}
