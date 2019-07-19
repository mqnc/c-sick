// g++ -o declarations -std=c++17 declarations.cpp && ./declarations

#include <string>
#include <tuple>
#include <iostream>
#include <utility>
#include <vector>

#include "kwargs.hpp"

// const a:=4 // always initialized
const auto a=4;

// var b:="bee"
auto b="bee";

// function const_arg(i:int); end
void const_arg(const int i){}

// function mutable_arg(var i:int); end
void mutable_arg(int i){}

// function default_arg(i:=1338); end
void default_arg(decltype(1338) i=1338){}

// function flexible_arg_type(var a); end
template <typename T0>
void flexible_arg_type(T0 a){}

// function[inline] with_specifiers;
inline void with_specifiers(){}

// function simple_return -> int
//    return 0
// end
auto simple_return() -> int{
    return 0;
}

// function dependeng_return_type(a) -> typeof(a)
//    return a*2
// end
template <typename T0>
auto dependeng_return_type(T0 a) -> decltype(a){
    return a*2;
}

// function return_tuple -> (string, var int)
//    return "take", 5
// end
auto return_tuple() -> std::tuple<std::string, int>{
    return std::tuple<const std::string, int>{"take", 5};
}

// function return_struct -> (var a:int, var b:string, var c:double)
// 	// does not work with typeof
//     return 1, "two", 3.0
// end
struct return_struct__return{
    int a;
    std::string b;
    double c;
    operator std::tuple<int, std::string, double>(){
        return {a, b, c};
    }
};
return_struct__return return_struct(){
    return {1, "two", 3.0};
}

// function return_auto_tuple(var a:int, var b:=0)
//     // back to medieval define-before-use times tho
//     return a*2, "awa"
// end
auto return_auto_tuple(int a, decltype(0) b=0){
    return std::make_tuple(a*2, "awa");
}

// function inc(x)
//     return x+1
// end
template <typename T0>
auto inc(T0 x){
    return x+1;
}

// kwargs can be used to kwargs-wrap functions of c++ libs
int func(int a, double b=.5, std::string c="c"){
    std::cout << a << b << c;
}

// kwargs func(a:int, b:=.5, c:="c") -> int
namespace func__params {
    std::size_t constexpr a = 0;
    std::size_t constexpr b = 1;
    std::size_t constexpr c = 2;
};

template<typename... Ts>
int func__kwargs(Ts&&... ts) {
    return func(
        kw::arg_get<0>(std::forward<Ts>
                (ts)...),
        kw::arg_get<1>(std::forward<Ts>
                (ts)..., kw::arg<1>(.5)),
        kw::arg_get<2>(std::forward<Ts>
                (ts)..., kw::arg<2>("c"))
    );
}

// are kwargs implicitly done for cinnamon functions?
// or only when there is a kwargs specifier (like an inline specifier)

int main(){

	// var k := return_tuple()
	auto k = return_tuple();

	// var k0, k1 := return_tuple()
	auto [k0, k1] = return_tuple();

	// k0, k1 := return_tuple()
	std::tie(k0, k1) = return_tuple();

	// k0, k1 := k0, k1+5
	std::tie(k0, k1) = /*static_cast<...>*/ std::make_tuple(k0, k1+5);
	// make tuple when right side of assignment is expression list

	// k0, k1 := k
	std::tie(k0, k1) = /*static_cast<...>*/ k;

	// var abc:= return_struct()
	auto abc = return_struct();
	
	// var sa, sb, sc := return_struct()
	auto [sa, sb, sc] = return_struct();

	// sa, sb, sc := return_struct()
	std::tie(sa, sb, sc) = static_cast<std::tuple<decltype(sa), decltype(sb), decltype(sc)>>(return_struct());
	// because of this we will always need the static_cast when using tie

	// func(1, 2)
	func(1, 2);

	// func(3, c:="cc")
	func__kwargs(3, kw::arg<func__params::c>("cc"));

	// const x:=scribble
	//     if a>2
	//         return a
	//     else
	//         return -a
	//     end
	// end + 3
	const auto x=[&](){
	    if(a>2){
		return a;
	    }
	    else{
		return -a;
	    }
	}() + 3;

	return 0;
}
