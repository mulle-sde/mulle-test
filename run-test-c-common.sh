SOURCE_EXTENSION=".c"
STANDALONE_SUFFIX="_standalone"

DEFAULTCFLAGS="-w -O0 -g"

if [ -z "${CC}" ]
then
   CC=cc
fi
