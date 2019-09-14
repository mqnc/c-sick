echo "test/cinnamon language/cinnamon.lua test/sandbox.mon test/sandbox.cpp" \
&& test/cinnamon language/cinnamon.lua test/sandbox.mon test/sandbox.cpp \
&& echo "g++ -o test/sandbox -std=c++17 -Wall -Wextra -g -pedantic -pthread test/sandbox.cpp" \
&& g++ -o test/sandbox -std=c++17 -Wall -Wextra -g -pedantic -pthread test/sandbox.cpp \
&& echo "test/sandbox" \
&& test/sandbox
