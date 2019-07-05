#include <iostream>
#include <string>
#include <utility>
#include <vector>

/*
Goal:
    If keyword arguments are present, they are first converted to positional
    arguments, as follows. First, a list of unfilled slots is created for the
    formal parameters. If there are N positional arguments, they are placed in
    the first N slots. Next, for each keyword argument, the identifier is used
    to determine the corresponding slot (if the identifier is the same as the
    first formal parameter name, the first slot is used, and so on). If the slot
    is already filled, a TypeError exception is raised. Otherwise, the value of
    the argument is placed in the slot, filling it (even if the expression is
    None, it fills the slot). When all arguments have been processed, the slots
    that are still unfilled are filled with the corresponding default value from
    the function definition.
    <docs.python.org/3.8/reference/expressions.html#calls>
*/

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

/*
Fn func(int a, double b:=.5, std::string c:="c") -> () :=
Endfn
*/

namespace func__params {
    std::size_t constexpr a = 0;
    std::size_t constexpr b = 1;
    std::size_t constexpr c = 2;
};

void func__impl(int a, double b, std::string c) {
    std::cout <<
        "a=" << a <<
        " b=" << b <<
        " c=" << c <<
        std::endl;
}

#ifdef notdef
template<typename... Ts>
void func(Ts&&... ts) {
    return kw::invoke(
        func__impl,
        std::make_index_sequence<3>(),
        std::forward<Ts>(ts)...,
        kw::arg<1>(.5),
        kw::arg<2>("c")
    );
}
#else
// More boilerplate in exchange for kw::invoke():
template<typename... Ts>
void func(Ts&&... ts) {
    return func__impl(
        kw::arg_get<0>(std::forward<Ts>(ts)...),
        kw::arg_get<1>(std::forward<Ts>(ts)..., kw::arg<1>(.5)),
        kw::arg_get<2>(std::forward<Ts>(ts)..., kw::arg<2>("c"))
    );
}
#endif

int Main(std::vector<std::string> args)
{
    // func(2, .25);
    func(2, .25);

    // func(2, c:="cc");
    func(2, kw::arg<func__params::c>("cc"));

    // func(2, .25, c:="cc");
    func(2, .25, kw::arg<func__params::c>("cc"));

    // func(2, c:="cc", .25);
    func(2, kw::arg<func__params::c>("cc"), .25);

    // func(2, c:="cc", b:=.25);
    func(2, kw::arg<func__params::c>("cc"), kw::arg<func__params::b>(.25));

    return 0;
}

int
main(int
c,char**v){return
Main(std::vector<std::string>(v,c+v));}
