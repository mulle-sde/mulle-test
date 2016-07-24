SOURCE_EXTENSION=".m .aam"
STANDALONE_SUFFIX="Standalone"

DEFAULTCFLAGS="-w -O0 -g -fobjc-runtime=mulle"

if [ -z "${CC}" ]
then
   CC=mulle-clang
fi

