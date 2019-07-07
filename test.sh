./test/cinnamon language/cinnamon.lua language/snippets/helloworld.mon test/helloworld.cpp \
&& cp -f language/cinnamon.h test/ \
&& g++ -o test/helloworld -std=c++17 -Wall -Wextra -g -pedantic -pthread test/helloworld.cpp \
&& test/helloworld
