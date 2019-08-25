// g++ -o struple -std=c++17 struple.cpp && ./struple && rm struple

#include <iostream>
#include <tuple>


// here I wanted to inherit from tuple and provide named references to the fields
// but I read that std::get would not work with it and we need to create our own get function
// and then the whole thing creates more mess than it solves

class struple:public std::tuple<int, int>{

};

int main(void){

	struple b(std::make_tuple(3,5));

	std::cout << "awa\n";
	return 0;
}
