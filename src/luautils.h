
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
	public:
		static lua_State* s_L;

		scope(lua_State* L)
		: m_prev(s_L)
		{
			s_L = L;
		}

		~scope()
		{
			s_L = m_prev;
		}

	private:
		lua_State* m_prev;
	};
	lua_State* scope::s_L = nullptr;

	class subscript_value;

	/**
	 * I represent a value of an arbitrary type on the Lua stack.
	 */
	class value {
		static void set_registry() {
			lua_settable(scope::s_L, LUA_REGISTRYINDEX);
		}

		static void get_registry() {
			lua_gettable(scope::s_L, LUA_REGISTRYINDEX);
		}

		static void push(const int value){
			lua_pushinteger(scope::s_L, value);
		}

		static void push(const std::string& value){
			lua_pushlstring(scope::s_L, value.data(), value.size());
		}

		static void push(const char *value){
			lua_pushstring(scope::s_L, value);
		}

		static void push(const StringPtr& value){
			lua_pushlstring(scope::s_L, value.c, value.len);
		}

		static void push(const value& value);
		static void push(const subscript_value& value);

	public:
		/**
		 * Create a value for the current top of the stack.
		 */
		value()
		{
			set_registry_slot();
		}

		/**
		 * Duplicate the given value.
		 */
		value(const value& val)
		{
			val.push();
			set_registry_slot();
		}

		/**
		 * An arbitrary value.
		 */
		template<typename TValue>
		explicit value(const TValue& val)
		{
			push(val);
			set_registry_slot();
		}

		~value() {
			lua_pushnil(scope::s_L);
			set_registry_slot();
		}

		/**
		 * Push this value's registry key.
		 */
		const value& key() const {
			lua_pushlightuserdata(scope::s_L, const_cast<value*>(this));
			return *this;
		}

		/**
		 * Push this value.
		 */
		const value& push() const {
			key();
			get_registry();
			return *this;
		}

		/**
		 * Return a string representation for this value.
		 */
		std::string tostring() const {
			push();
			std::size_t len;
			const char* s = lua_tolstring(scope::s_L, -1, &len);
			std::string result(s, len);
			lua_pop(scope::s_L, 1);
			return result;
		}

		/**
		 * If this value represents a table, get the given slot.
		 */
		template<typename TKey>
		value gettable(const TKey& key) const {
			push();
			push(key);
			lua_gettable(scope::s_L, -2);
			value result;
			lua_pop(scope::s_L, 1);
			return result;
		}

		/**
		 * If this value represents a table, set the given slot.
		 */
		template<typename TKey, typename TValue>
		const value& settable(const TKey& key, const TValue& value) const {
			push();
			push(key);
			push(value);
			lua_settable(scope::s_L, -3);
			lua_pop(scope::s_L, 1);
			return *this;
		}

		template<typename TKey>
		subscript_value operator[](const TKey& key) const;

		/**
		 * If this value is callable, call it with the given arguments.
		 */
		template<typename... Args>
		value operator()(const Args&... args) const {
			push();
			detail::invoke_with_arg(
				[this](const auto& arg) {
					push(arg);
				},
				args...
			);
			lua_pcall(scope::s_L, sizeof...(Args), 1, 0);
			return value();
		}

	private:
		/**
		 * Set our slot in the registry to the value at the top of
		 * the stack.
		 */
		void set_registry_slot() {
			key();
			lua_rotate(scope::s_L, -2, 1);
			set_registry();
		}
	};

	inline value globals() {
		lua_pushglobaltable(scope::s_L);
		return value();
	}

	inline value newtable() {
		lua_newtable(scope::s_L);
		return value();
	}

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
			m_key.push();
			lua_gettable(scope::s_L, -2);
			lua_rotate(scope::s_L, -2, 1);
			lua_pop(scope::s_L, 1);
			return *this;
		}

		/**
		 * @param value Value to assign to this table slot.
		 */
		template<typename TValue>
		const subscript_value& operator=(const TValue& value) const {
			m_table.settable(m_key, value);
			return *this;
		}

	private:
		const value& m_table;
		const value m_key;
	};

	void value::push(const value& value) {
		value.push();
	}

	void value::push(const subscript_value& value) {
		value.push();
	}

	template<typename TKey>
	subscript_value value::operator[](const TKey& key) const {
		return subscript_value(*this, key);
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
