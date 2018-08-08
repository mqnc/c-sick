
#pragma once

#include <string>
#include "lua/src/lua.hpp"

// utilities for lua stack manipulation
struct StringPtr{
	StringPtr(const char* const c_, const std::size_t len_):c(c_),len(len_){}
	const char* const c;
	const std::size_t len;
};

namespace lua {
	namespace detail {
		template<typename Func>
		void invoke_with_arg(Func)
		{}

		template<typename Func, typename Arg0, typename... Args>
		void invoke_with_arg(Func func, Arg0&& arg0, Args&&... args) {
			func(std::forward<Arg0>(arg0));
			return invoke_with_arg(std::move(func), std::forward<Args>(args)...);
		}
	}

	class scope {
		static lua_State* s_L;

	public:
		static lua_State* state() {
			return s_L;
		}

		scope(lua_State* L)
		: m_prev(s_L)
		{
			s_L = L;
		}

		~scope() {
			s_L = m_prev;
		}

	private:
		lua_State* m_prev;
	};
	lua_State* scope::s_L = nullptr;

	/**
	 * I clean up the stack on scope exit.
	 */
	class stack_scope {
	public:
		explicit stack_scope(int n = 1)
		: m_n(n)
		{}

		stack_scope(const stack_scope&) = delete;
		stack_scope& operator =(const stack_scope&) = delete;

		~stack_scope() {
			lua_pop(scope::state(), m_n);
		}

		void increase(int n = 1) {
			m_n += n;
		}

		void decrease(int n = 1) {
			m_n -= n;
		}

	private:
		int m_n;
	};

	/**
	 * An exception indicating that a Lua error is at the top of the
	 * stack.
	 */
	class exception {
	};

	class subscript_value;

	/**
	 * I represent a value of an arbitrary type on the Lua stack.
	 */
	class value {
		static void push(const bool value){
			lua_pushboolean(scope::state(), value);
		}

		static void push(const int value){
			lua_pushinteger(scope::state(), value);
		}

		static void push(const size_t value){
			lua_pushinteger(scope::state(), value);
		}

		static void push(const std::string& value){
			lua_pushlstring(scope::state(), value.data(), value.size());
		}

		static void push(const char *value){
			lua_pushstring(scope::state(), value);
		}

		static void push(const StringPtr& value){
			lua_pushlstring(scope::state(), value.c, value.len);
		}

		static void push(void* value){
			lua_pushlightuserdata(scope::state(), value);
		}

		static void push(const lua_CFunction value){
			lua_pushcfunction(scope::state(), value);
		}

		static void push(const value& value) {
			value.push();
		}

		static void push(const subscript_value& value);

	public:
		/**
		 * Create a value for the current top of the stack.
		 */
		static value pop() {
			return value().assign();
		}

		/**
		 * Create a value for the given stack slot.
		 */
		static value at(const int index = -1) {
			lua_pushvalue(scope::state(), index);
			return pop();
		}

		/**
		 * A nil value.
		 */
		value()
		{}

		/**
		 * Duplicate the given value.
		 */
		value(const value& val)
		{
			val.push();
			assign();
		}

		/**
		 * An arbitrary value.
		 */
		template<typename TValue>
		explicit value(const TValue& val)
		{
			push(val);
			assign();
		}

		~value() {
			lua_pushnil(scope::state());
			assign();
		}

		/**
		 * Push this value.
		 */
		const value& push() const {
			lua_rawgetp(scope::state(), LUA_REGISTRYINDEX, const_cast<value*>(this));
			return *this;
		}

		/**
		 * Assign the value at the top of the stack to this object.
		 */
		value& assign() {
			lua_rawsetp(scope::state(), LUA_REGISTRYINDEX, this);
			return *this;
		}

		/**
		 * Whether this value is nil.
		 */
		bool isnil() const {
			push();
			stack_scope ss;
			return lua_isnil(scope::state(), -1);
		}

		/**
		 * Return a boolean representation for this value.
		 */
		bool toboolean() const {
			push();
			stack_scope ss;
			return lua_toboolean(scope::state(), -1);
		}

		/**
		 * Return a string representation for this value.
		 */
		std::string tostring() const {
			push();
			stack_scope ss;
			std::size_t len;
			const char* s = lua_tolstring(scope::state(), -1, &len);
			return std::string(s, len);
		}

		/**
		 * Return a userdata representation for this value.
		 */
		void* touserdata() const {
			push();
			stack_scope ss;
			return lua_touserdata(scope::state(), -1);
		}

		/**
		 * If this value represents a table, get the given slot.
		 */
		template<typename TKey>
		value gettable(const TKey& key) const {
			push();
			stack_scope ss;
			push(key);
			lua_gettable(scope::state(), -2);
			return pop();
		}

		/**
		 * If this value represents a table, set the given slot.
		 */
		template<typename TKey, typename TValue>
		const value& settable(const TKey& key, const TValue& value) const {
			push();
			stack_scope ss;
			push(key);
			push(value);
			lua_settable(scope::state(), -3);
			return *this;
		}

		template<typename TKey>
		subscript_value operator [](const TKey& key) const;

		/**
		 * If this value is callable, call it with the given arguments.
		 * @throw lua::exception on error.
		 */
		template<typename... Args>
		value operator ()(const Args&... args) const {
			push();
			detail::invoke_with_arg(
				[this](const auto& arg) {
					push(arg);
				},
				args...
			);
			if (LUA_OK != lua_pcall(scope::state(), sizeof...(Args), 1, 0)) {
				throw exception();
			}
			return pop();
		}
	};

	/**
	 * I represent an individual Lua table slot and allow assignment to it.
	 */
	class subscript_value {
	public:
		template<typename TKey>
		subscript_value(const value& table, const TKey& key)
		: m_table(table)
		, m_key(key)
		{}

		/**
		 * Push the value contained in this table slot.
		 */
		const subscript_value& push() const {
			m_table.push();
			stack_scope ss;
			m_key.push();
			lua_gettable(scope::state(), -2);
			lua_rotate(scope::state(), -2, 1);
			return *this;
		}

		/**
		 * @param value Value to assign to this table slot.
		 */
		template<typename TValue>
		const subscript_value& operator =(const TValue& value) const {
			m_table.settable(m_key, value);
			return *this;
		}

	private:
		const value& m_table;
		const value m_key;
	};

	inline void value::push(const subscript_value& value) {
		value.push();
	}

	template<typename TKey>
	subscript_value value::operator [](const TKey& key) const {
		return subscript_value(*this, key);
	}

	inline value globals() {
		lua_pushglobaltable(scope::state());
		return value::pop();
	}

	inline value newtable() {
		lua_newtable(scope::state());
		return value::pop();
	}

	/**
	 * Invoke a C++ function from Lua. The Lua state is made available to
	 * the function via lua::scope. The function receives its arguments on
	 * the stack and returns a single lua::value.
	 */
	template<lua::value(&f)()>
	int invoke(lua_State* L) {
		try {
			const scope luascope(L);
			f().push();
			return 1;
		} catch (lua::exception&) {
			return lua_error(L);
		}
	}

	/**
	 * This is intended to be used by functions invoked using
	 * lua::invoke(). It takes an error message and does not return.
	 */
	template<typename T>
	void error(const T& msg) {
		value(msg).push();
		throw exception();
	}
}

inline auto lua_loadutils(lua_State *L){
	const auto utils = R"(

	function stringify(o)
		if "table" ~= type(o) then
				return tostring(o)
		end

		local res = {}
		for k, v in pairs(o) do
				local val = {"[", k, "]=", stringify(v)}
				res[1 + #res] = table.concat(val)
		end
		return "{" .. table.concat(res, ", ") .. "}"
	end

	)";
	return luaL_loadstring(L, utils) || lua_pcall(L, 0, 0, 0);
}
