#! /bin/sh
#
# assume:
#   project/CMakeLists.txt
#   project/dependencies
#   project/addictions
#   project/tests/<us.sh>
#
# PWD=project/tests  <--- we are here
#
# create:
#   project/tests/lib
#   project/tests/include
# using:
#   project/tests/build
#

usage()
{
   cat <<EOF >&2
usage: build-for-test.sh [-f]

   -d   : rebuild parent depedencies
   -j   : number of cores parameter for make (${CORES})
EOF
}


CORES="${CORES:-2}"


while :
do
   if [ "$1" = "-h" -o "$1" = "--help" ]
   then
      usage >&2
      exit 1
   fi

   if [ "$1" = "-d" ]
   then
      REBUILD="YES"
      [ $# -eq 0 ] || shift
      continue
   fi

   if [ "$1" = "-j" ]
   then
      if [ $# -eq 0 ]
      then
         fail "core count missing"
      fi
      shift

      CORES="$1"
      [ $# -eq 0 ] || shift
      continue
   fi

   break
done


BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
OSX_SYSROOT="${OSX_SYSROOT:-macosx}"
if [ -z "${BUILD_OPTIONS}" ]
then
   BUILD_OPTIONS="-c Debug -k"
fi

if [ "${REBUILD}" = "YES" -a -d ../.bootstrap ]
then
   if [ ! -d ../.repos -a ! -d ../archive ]
   then
      ( cd .. ; mulle-bootstrap fetch )
   fi
   ( cd .. ; mulle-bootstrap build ${BUILD_OPTIONS} "$@" )
fi


prefix="`pwd -P`"

if [ ! -f "../CMakeLists.txt" ]
then
   echo "No CMakeLists.txt file found. So only dependencies may have been built." >&2
   exit 0
fi

if [ ! -d "${BUILD_DIR}" ]
then
   mkdir "${BUILD_DIR}" 2> /dev/null
fi

cd "${BUILD_DIR}" || exit 1
cmake "-DCMAKE_OSX_SYSROOT=${OSX_SYSROOT}" \
      "-DCMAKE_INSTALL_PREFIX=${prefix}" \
      "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" \
      ../.. || exit 1
make install
