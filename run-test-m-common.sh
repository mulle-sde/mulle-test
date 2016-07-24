SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

DEFAULTCFLAGS="-w -O0 -g -fmulle-objc"

if [ -z "${CC}" ]
then
   CC=mulle-clang
fi

