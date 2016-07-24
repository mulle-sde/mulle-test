#! /bin/sh

set -e

cd ..
if [ -d .bootstrap ]
then
   mulle-bootstrap build -c Debug -k "$@"
fi

if [ -f "CMakeLists.txt" ]
then
   cd build
   cmake -DCMAKE_OSX_SYSROOT=macosx -DCMAKE_INSTALL_PREFIX="`pwd`/.." -DCMAKE_BUILD_TYPE=Debug ..
   make install
else
   echo "No CMakeLists.txt file found. So only dependencies have been built." >&2
fi
