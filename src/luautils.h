
#pragma once

#include <string>
#include "lua/src/lua.hpp"

// utilities for lua stack manipulation
struct LuaStackPtr{
	explicit LuaStackPtr(const int idx_):idx(idx_){}
	const int idx;
};

struct StringPtr{
	StringPtr(const char* const c_, const std::size_t len_):c(c_),len(len_){}
	const char* const c;
	const std::size_t len;
};

inline void lua_push(lua_State *L, const int value){
	lua_pushinteger(L, value);
}
inline void lua_push(lua_State *L, const std::string& value){
	lua_pushlstring(L, value.data(), value.size());
}
inline void lua_push(lua_State *L, const char *value){
	lua_pushstring(L, value);
}
inline void lua_push(lua_State *L, const StringPtr& value){
	lua_pushlstring(L, value.c, value.len);
}
inline void lua_push(lua_State *L, const LuaStackPtr value){
	lua_pushvalue(L, value.idx);
}

namespace lua {
	class value;
}

void lua_push(lua_State* L, const lua::value& value);

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

	class subscript_value;

	/**
	 * I represent a value of an arbitrary type on the Lua stack.
	 */
	class value {
		static void set_registry(lua_State& L) {
			lua_settable(&L, LUA_REGISTRYINDEX);
		}

		static void get_registry(lua_State& L) {
			lua_gettable(&L, LUA_REGISTRYINDEX);
		}

	public:
		/**
		 * An arbitrary value.
		 */
		template<typename TValue>
		value(lua_State& L, const TValue& val)
		: m_L(L)
		{
			lua_push(&L, val);
			settable();
		}

		/**
		 * Create a value for the current top of the stack.
		 */
		explicit value(lua_State& L)
		: m_L(L)
		{
			settable();
		}

		/**
		 * Duplicate the given value.
		 */
		value(const value& val)
		: m_L(val.m_L)
		{
			val.push();
			settable();
		}

		~value() {
			lua_pushnil(&m_L);
			settable();
		}

		lua_State& state() const {
			return m_L;
		}

		/**
		 * Push this value's registry key.
		 */
		void key() const {
			lua_pushlightuserdata(&m_L, const_cast<value*>(this));
		}

		/**
		 * Push this value.
		 */
		void push() const {
			key();
			get_registry(m_L);
		}

		/**
		 * Return a LuaStackPtr for this value.
		 */
		LuaStackPtr slot() const {
			push();
			return LuaStackPtr(lua_gettop(&m_L));
		}

		/**
		 * Return a string representation for this value.
		 */
		std::string tostring() const {
			push();
			std::size_t len;
			const char* s = lua_tolstring(&m_L, -1, &len);
			std::string result(s, len);
			lua_pop(&m_L, 1);
			return result;
		}

		/**
		 * If this value represents a table, set the given slot.
		 */
		template<typename TKey, typename TValue>
		const value& set(const TKey& key, const TValue& value) const {
			push();
			lua_push(&m_L, key);
			lua_push(&m_L, value);
			lua_settable(&m_L, -3);
			lua_pop(&m_L, 1);
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
					lua_push(&m_L, arg);
				},
				args...
			);
			lua_pcall(&m_L, sizeof...(Args), 1, 0);
			return value(m_L);
		}

	private:
		void settable() {
			key();
			lua_rotate(&m_L, -2, 1);
			set_registry(m_L);
		}

		lua_State& m_L;
	};

	inline value getglobal(lua_State& L, const char* name) {
		lua_getglobal(&L, name);
		return value(L);
	}

	inline value newtable(lua_State& L) {
		lua_newtable(&L);
		return value(L);
	}

	/**
	 * I represent an individual Lua table slot and allow assignment to it.
	 */
	class subscript_value {
	public:
		template<typename TKey>
		subscript_value(const value& table, const TKey& key)
		: m_table(table)
		, m_key(table.state(), key)
		{}

		template<typename TValue>
		const subscript_value& operator=(const TValue& value) const {
			m_table.set(m_key, value);
			return *this;
		}

	private:
		const value& m_table;
		const value m_key;
	};

	template<typename TKey>
	subscript_value value::operator[](const TKey& key) const {
		return subscript_value(*this, key);
	}
}

inline void lua_push(lua_State*, const lua::value& value) {
	value.push();
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
