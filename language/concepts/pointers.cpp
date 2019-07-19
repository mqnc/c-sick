// g++ -o pointers -std=c++17 pointers.cpp && ./pointers

#include <memory>
#include "noisy.hpp"
#include "pointers.hpp"

template<typename T>
std::weak_ptr<T> get_weak(const std::shared_ptr<T>& p){
	return p;
}

template<typename T>
std::shared_ptr<T> lock(const std::weak_ptr<T>& p){
	return p.lock();
}

template<typename T>
VolatilePtr<T> get_volatile(Stackbox<T>& s){
	return s.ptr();
}

// function f(x:unique[int]) -> unique[int]
auto f(std::unique_ptr<int> x) -> std::unique_ptr<int>;

// function f(x:shared[int]) -> shared[int]
auto f(std::shared_ptr<int> x) -> std::shared_ptr<int>;

// c++ guidelines suggest raw access for parameters, do we want that?

int main(){
	
	// var upint := make_unique[int](5)
	auto upint = std::make_unique<int>(5);

	// var upint2 := move(upint)
	auto upint2 = std::move(upint);

	// var spint := make_shared[int](6)
	auto spint = std::make_shared<int>(6);

	// var wpint := get_weak(spint)
	auto wpint = get_weak(spint);

	// var spint2 := lock(wpint)
	auto spint2 = lock(wpint);

	// var i := @spint2
	auto i = *spint2;

	// var box = make_stackbox[Noisy]("awa")
	auto box = make_stackbox<Noisy>("awa");
	
	// var vpbox = get_volatile(sbint)
	auto vpbox = get_volatile(box);

}