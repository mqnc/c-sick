#include <string>

class Noisy
{
public:
	Noisy()
	{
		std::cout << "constructed without name\n";
	}

	explicit Noisy(std::string const& name)
	: name{name}
	{
		std::cout << "constructed " << name << '\n';
	}

	Noisy(Noisy const& other)
	: name(other.name)
	{
		std::cout << "copy-constructed from " << name << '\n';
	}

	Noisy(Noisy&& other) noexcept
	: name(std::forward<decltype(other.name)>(other.name))
	{
		other.name = "ex-" + name;
		std::cout << "move-constructed from " << name << '\n';
	}

	Noisy& operator =(Noisy const& other)
	{
		name = other.name;
		std::cout << "copy-assigned from " << name << '\n';
		return *this;
	}

	Noisy& operator =(Noisy&& other) noexcept
	{
		name = std::forward<decltype(other.name)>(other.name);
		other.name = "ex-" + name;
		std::cout << "move-assigned from " << name << '\n';
		return *this;
	}

	~Noisy()
	{
		std::cout << "destructed " << name << '\n';
	}

	std::string name{"(noname)"};
};
