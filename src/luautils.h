
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

inline void lua_closefield(lua_State *L){
	lua_settable(L, -3);
}

template<typename TKey, typename TVal>
void lua_pushfield(lua_State *L, const TKey& key, const TVal& value){
	lua_push(L, key);
	lua_push(L, value);
	lua_closefield(L);
}

template<typename TKey>
void lua_opensubtable(lua_State *L, const TKey& key){
	lua_push(L, key);
	lua_newtable(L);
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
