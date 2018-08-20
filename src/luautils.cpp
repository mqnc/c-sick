#include "luautils.h"

namespace lua {
	lua_State* scope::s_L = nullptr;

	void value::push(const subscript_value& value) {
		value.push();
	}

	value globals() {
		lua_pushglobaltable(scope::state());
		return value::pop();
	}

	value newtable() {
		lua_newtable(scope::state());
		return value::pop();
	}

	void* detail::newuserdata(const char* const name,
				  const std::size_t size,
				  const lua_CFunction finalize,
				  const method* methods,
				  const method* const methodsEnd)
	{
		lua_State* const L = scope::state();

		void* const t = lua_newuserdata(L, size);
		if (luaL_newmetatable(L, name)) {
			lua_pushcfunction(L, finalize);
			lua_setfield(L, -2, "__gc");
			lua_newtable(L);
			for (; methods != methodsEnd; ++methods) {
				lua_pushcfunction(L, methods->f);
				lua_setfield(L, -2, methods->name);
			}
			lua_setfield(L, -2, "__index");
		}
		lua_setmetatable(L, -2);

		return t;
	}
}

bool lua_loadutils(lua_State *L)
{
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
