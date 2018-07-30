env = Environment(TARGET_ARCH = 'x86')

#
# Common configuration.
#
env.VariantDir("build", "src")
env.AppendUnique(CPPDEFINES=["LUA_COMPAT_5_2"])
env.AppendUnique(CPPPATH=["src/lua/src"])

#
# Platform-specific configuration.
#
if env["PLATFORM"] in ["aix", "darwin", "posix", "sunos"]:
	env.AppendUnique(CPPDEFINES=["LUA_USE_POSIX"])
	env.AppendUnique(LIBS=["m"])

#
# Tool-specific configuration.
#
# Export all symbols to support dynamically loaded packages.
if "applelink" in env["TOOLS"]:
	env.AppendUnique(LINKFLAGS=["-Wl,-export_dynamic"])

if "gnulink" in env["TOOLS"]:
	env.AppendUnique(LINKFLAGS=["-Wl,-E"])

if "msvc" in env["TOOLS"]:
	#env.AppendUnique(CXXFLAGS=["/O2"])
	#env.AppendUnique(CXXFLAGS=["/DEBUG"])
	env.AppendUnique(CXXFLAGS=["/EHsc"])

else:
	env.AppendUnique(CCFLAGS=["-Wall", "-Wextra", "-g", "-pedantic", "-pthread"])
	env.AppendUnique(CFLAGS=["-std=gnu99"])
	env.AppendUnique(CXXFLAGS=["-std=c++14"])
	env.AppendUnique(LINKFLAGS=["-pthread"])

#
# Detect and add optional libs.
#
if not GetOption("clean") and not GetOption("help"):
	config = Configure(env)

	# AIX, Linux and Solaris require -ldl for dlopen(), BSD and Darwin
	# don't.
	use_dlopen = config.CheckLibWithHeader(
		[None, "dl"], "dlfcn.h", "c", call='dlopen("", 0);'
	)
	if use_dlopen:
		config.env.AppendUnique(CPPDEFINES=["LUA_USE_DLOPEN"])

	env = config.Finish()

luasrc = Glob("build/lua/src/*.c", exclude="build/lua/src/lua*.c")
#env.Program("lua", ["build/lua/src/lua.c"] + luasrc)
#env.Program("luac", ["build/lua/src/luac.c"] + luasrc)
env.Program("program", ["build/main.cpp"] + luasrc)