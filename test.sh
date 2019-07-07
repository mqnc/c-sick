
cp -f language/cinnamon.h test/

FILES=language/snippets/*

echo $FILES

for INFILE in $FILES
do
	FILEMON=`echo $INFILE | sed 's/language\/snippets\///'`
	FILE=`echo $FILEMON | sed 's/.mon//'`

	rm test/$FILE
	./test/cinnamon language/cinnamon.lua language/snippets/$FILE.mon test/$FILE.cpp \
	&& g++ -o test/$FILE -std=c++17 -Wall -Wextra -g -pedantic -pthread test/$FILE.cpp
done

echo "- - - - - - - - - - 8< - - - - - - - - - -"

for INFILE in $FILES
do
	FILEMON=`echo $INFILE | sed 's/language\/snippets\///'`
	FILE=`echo $FILEMON | sed 's/.mon//'`

	test/$FILE
done
