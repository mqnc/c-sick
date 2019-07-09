
./test/cinnamon language/cinnamon.lua

cp -f language/cinnamon.h test/

FILES=language/snippets/*

echo $FILES

for INFILE in $FILES
do
	echo "\n- - - - - - - - - -8< - - - - - - - - -\n"

	FILEMON=`echo $INFILE | sed 's/language\/snippets\///'`
	FILE=`echo $FILEMON | sed 's/.mon//'`

	cp -f $INFILE test/
	rm test/$FILE
	./test/cinnamon language/cinnamon.lua test/$FILE.mon test/$FILE.cpp \
	&& g++ -o test/$FILE -std=c++17 -Wall -Wextra -g -pedantic -pthread test/$FILE.cpp

	echo "\n"
	test/$FILE
	echo "\n"
done
