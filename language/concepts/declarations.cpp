// g++ -o declarations -std=c++17 declarations.cpp && ./declarations

#include <string>
#include <tuple>
#include <iostream>
#include <utility>
#include <vector>

// kwargs.hpp
/**
 * Return an lvalue ref if the argument is an lvalue (ref), or an rvalue ref
 * otherwise. That is, return an rvalue ref if and only if the argument is
 * owned.
 */
#define move_if_owned(e) (std::forward<decltype(e)>(e))

namespace kw {
    namespace detail {
        /**
         * An arg_wrap<I, T> contains a single argument value tagged with its
         * index.
         */
        template<std::size_t I, typename T>
        struct arg_wrap {
            T t;
        };
    }

    template<std::size_t I, typename T>
    auto arg(T&& t) {
        return detail::arg_wrap<I, decltype(t)>{ std::forward<T>(t) };
    }

    namespace detail {
        /**
         * The function arg_get_helper extracts the first arg_wrap<> with index
         * N or the positional argument at index I, whichever is found first.
         */
        template<std::size_t N, std::size_t I, typename... Ts>
        struct arg_get_helper {
            static int apply(Ts&&...) {
                static_assert(0 != sizeof...(Ts), "Missing required parameter.");
            }
        };

        /**
         * The function arg_get_helper_i extracts the first argument if I == 0
         * or calls arg_get_helper with I - 1 and the remaining arguments.
         */
        template<std::size_t N, std::size_t I, typename T, typename... Ts>
        struct arg_get_helper_i {
            static decltype(auto) apply(T&&, Ts&&... ts) {
                return arg_get_helper<N, I - 1, Ts...>::apply(std::forward<Ts>(ts)...);
            }
        };

        template<std::size_t N, typename T, typename... Ts>
        struct arg_get_helper_i<N, 0, T, Ts...> {
            static decltype(auto) apply(T&& t, Ts&&...) {
                return std::forward<T>(t);
            }
        };

        /**
         * The function arg_get_helper_w unwraps the first argument if it is
         * arg_wrap<M, T> and M == N or calls arg_get_helper with the remaining
         * arguments.
         */
        template<std::size_t N, std::size_t M, std::size_t I, typename T, typename... Ts>
        struct arg_get_helper_w {
            static decltype(auto) apply(arg_wrap<M, T>, Ts&&... ts) {
                return arg_get_helper<N, I, Ts...>::apply(std::forward<Ts>(ts)...);
            }
        };

        template<std::size_t N, std::size_t I, typename T, typename... Ts>
        struct arg_get_helper_w<N, N, I, T, Ts...> {
            static decltype(auto) apply(arg_wrap<N, T> const& a, Ts&&...) {
                return a.t;
            }

            static decltype(auto) apply(arg_wrap<N, T>&& a, Ts&&...) {
                return move_if_owned(a.t);
            }
        };

        template<std::size_t N, std::size_t I, typename T, typename... Ts>
        struct arg_get_helper<N, I, T, Ts...> {
            static decltype(auto) apply(T&& t, Ts&&... ts) {
                return arg_get_helper_i<N, I, T, Ts...>::apply(
                    std::forward<T>(t),
                    std::forward<Ts>(ts)...
                );
            }
        };

        template<std::size_t N, std::size_t M, std::size_t I, typename T, typename... Ts>
        struct arg_get_helper<N, I, arg_wrap<M, T>, Ts...> {
        	static decltype(auto) apply(arg_wrap<M, T> const& a, Ts&&... ts) {
        	    return arg_get_helper_w<N, M, I, T, Ts...>::apply(
        	        a,
        	        std::forward<Ts>(ts)...
        	    );
        	}

        	static decltype(auto) apply(arg_wrap<M, T>&& a, Ts&&... ts) {
        	    return arg_get_helper_w<N, M, I, T, Ts...>::apply(
        	        std::move(a),
        	        std::forward<Ts>(ts)...
        	    );
        	}
        };
    }

    /**
     * The function arg_get extracts the first argument with the given index
     * from a sequence of positional arguments and arg_wrap<>s.
     */
    template<std::size_t I, typename... Ts>
    decltype(auto) arg_get(Ts&&... ts) {
        return detail::arg_get_helper<I, I, Ts...>::apply(std::forward<Ts>(ts)...);
    }

    /**
     * Invoke the given function with the arguments indicated by the index
     * sequence extracted from the argument sequence.
     */
    template<typename Func, std::size_t... Is, typename... Ts>
    auto invoke(Func&& func, std::index_sequence<Is...>, Ts&&... ts) {
        return std::forward<Func>(func)(arg_get<Is>(std::forward<Ts>(ts)...)...);
    }
}

/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

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
// implicitly done for functions defined in cinnamon (?)
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
