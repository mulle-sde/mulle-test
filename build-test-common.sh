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
usage: build-test.sh [-dj]

   -d   : rebuild parent depedencies
   -j   : number of cores parameter for make (${CORES})
EOF
   exit 1
}


CORES="${CORES:-2}"

while [ $# -ne 0 ]
do
   case "$1" in
      -h|--help)
         usage
      ;;

      -d)
         REBUILD="YES"
      ;;

      -t)
         set -x
      ;;

      -v)
      	MAKE_FLAGS="${MAKE_FLAGS} VERBOSE=1"
      ;;

      -j)
         shift
         [ $# -eq 0 ] && usage

         CORES="$1"
      ;;

      -*)
         usage
      ;;

      *)
         break
      ;;
   esac

   shift
done

#
# build non-debug as a default
#
BUILD_DIR="${BUILD_DIR:-build}"
BUILD_OPTIONS="${BUILD_OPTIONS:--k}"
BUILD_TYPE="${BUILD_TYPE:-Release}"

DEPENDENCIES_DIR="${DEPENDENCIES_DIR:-dependencies}"
INSTALL_PREFIX="`pwd -P`"
OSX_SYSROOT="${OSX_SYSROOT:-macosx}"

if [ "${REBUILD}" = "YES" -a -d ../.bootstrap ]
then
   if [ ! -d ../.repos -a ! -d ../archive ]
   then
      ( cd .. ; mulle-bootstrap fetch )
   fi
   ( cd .. ; mulle-bootstrap build ${BUILD_OPTIONS} "$@" )
fi


if [ ! -f "../CMakeLists.txt" ]
then
   echo "No CMakeLists.txt file found. So only dependencies may have been built." >&2
   exit 0
fi

if [ ! -z "${CC}" ]
then
   CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_C_COMPILER=${CC}"
fi

if [ ! -z "${CXX}" ]
then
   CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_CXX_COMPILER=${CXX}"
fi


if [ ! -d "${BUILD_DIR}" ]
then
   mkdir "${BUILD_DIR}" 2> /dev/null
fi

cd "${BUILD_DIR}" || exit 1

${CMAKE} -G "${CMAKE_GENERATOR}" \
      "-DCMAKE_OSX_SYSROOT=${OSX_SYSROOT}" \
      "-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}" \
      "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" \
      "-DDEPENDENCIES_DIR=${DEPENDENCIES_DIR}" \
      "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" \
      ${CMAKE_FLAGS} \
      ../.. || exit 1

${MAKE} ${MAKE_FLAGS}  install
