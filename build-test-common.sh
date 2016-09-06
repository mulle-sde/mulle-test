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


mingw_mangle_compiler_exe()
{
   local compiler

   compiler="$1"
   case "${compiler}" in
      mulle-clang-cl.exe)
      	:
      ;;

      clang.exe)
      	compiler="clang-cl.exe"
      ;;

      mulle-clang|clang)
         compiler="${compiler}-cl.exe"
      ;;

      *)
         compiler="cl.exe"
         echo "Using default compiler cl" >&2
      ;;
   esac
   echo "${compiler}"
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


BUILD_RELATIVE_DEPENDENCIES_DIR="${BUILD_RELATIVE_DEPENDENCIES_DIR:-../../dependencies}"

BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
OSX_SYSROOT="${OSX_SYSROOT:-macosx}"
BUILD_OPTIONS="${BUILD_OPTIONS:--c Debug -k}"
prefix="`pwd -P`"


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

case "`uname`" in
   MINGW*)
      CC="`mingw_mangle_compiler_exe "${CC}"`"
      CXX="`mingw_mangle_compiler_exe "${CXX}"`"
      CMAKE="${CMAKE:-cmake}"
      if [ -z "${CC}" ]
      then
         MAKE="${MAKE:-nmake}"
      fi

      case "${MAKE}" in
         nmake)
            CMAKE_GENERATOR="NMake Makefiles"
         ;;

         make|ming32-make|"")
            CMAKE="mulle-mingw-cmake.sh"
            MAKE="mulle-mingw-make.sh"
            CMAKE_GENERATOR="MinGW Makefiles"
            CC="${CC:-cl}"
            CXX="${CXX:-cl}"
         ;;

         *)
            CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
         ;;
      esac
   ;;

   *)
      CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
      CMAKE="${CMAKE:-cmake}"
      MAKE="${MAKE:-make}"
   ;;
esac

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
      "-DCMAKE_INSTALL_PREFIX=${prefix}" \
      "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" \
      "-DBUILD_RELATIVE_DEPENDENCIES_DIR=${BUILD_RELATIVE_DEPENDENCIES_DIR}" \
      "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" \
      ${CMAKE_FLAGS} \
      ../.. || exit 1

${MAKE} ${MAKE_FLAGS}  install
