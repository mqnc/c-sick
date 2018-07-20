
import sys, os

# recursively scan folder
def getCppFiles(dir):
	files = []

	elems = os.listdir(dir)
	for elem in elems:
		dir_elem = os.path.join(dir, elem)
		if os.path.isdir(dir_elem):
			files += getCppFiles(dir_elem).copy()
		elif elem[-4:] == ".cpp" or elem[-2:] == ".c":
			files += [dir_elem]

	return files

env = Environment(TARGET_ARCH = 'x86')
if "msvc" in env["TOOLS"]:
	#env.AppendUnique(CXXFLAGS=["/O2"])
	#env.AppendUnique(CXXFLAGS=["/DEBUG"])
	env.AppendUnique(CXXFLAGS=["/EHsc"])
elif "clangxx" in env["TOOLS"] or "g++" in env["TOOLS"]:
	env.AppendUnique(CXXFLAGS=["-std=c++14"])

env.VariantDir('build', 'src')
env.AppendUnique(CPPDEFINES=["LUA_COMPAT_5_2"])
env.AppendUnique(CPPPATH=["src/lua/src"])

cpps = getCppFiles("src")

for i in range(len(cpps)):
	cpps[i] = "build" + cpps[i][3:]

lua = cpps.copy()
lua = [x for x in lua if not x.endswith("luac.c") and not x.endswith("main.cpp")]
luac = cpps.copy()
luac = [x for x in luac if not x.endswith("lua.c") and not x.endswith("main.cpp")]
prog = cpps.copy()
prog = [x for x in prog if not x.endswith("luac.c") and not x.endswith("lua.c")]

#env.Program('lua', lua)
#env.Program('luac', luac)
env.Program('program', prog)
