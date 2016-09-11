#! /bin/sh

REQUIRED_FUNCTIONS_MIN_MAJOR=2
REQUIRED_FUNCTIONS_MIN_MINOR=0


mingw_demangle_path()
{
   echo "$1" | sed 's|^/\(.\)|\1:|' | sed s'|/|\\|g'
}


mingw_mangle_compiler_exe()
{
   local compiler

   compiler="$1"
   case "${compiler}" in
      mulle-clang|clang)
         compiler="${compiler}-cl.exe"
      ;;

      mulle-clang-*|clang-*)
         :
      ;;

      *)
         compiler="cl.exe"
         echo "Using default compiler cl for $2" >&2
      ;;
   esac
   echo "${compiler}"
}


check_version()
{
   local min_major
   local min_minor
   local version

   version="$1"
   min_major="$2"
   min_minor="$3"

   local arewegood
   local major
   local minor

   arewegood="NO"
   [ -z "${version}" -o  -z "${min_major}" -o -z "${min_minor}" ] && echo "parameter error in check_version" >&2 && exit 1

   major="`echo "${version}" | head -1 | cut -d. -f1`"
   if [ "${major}" -ge "${min_major}" ]
   then
      arewegood="YES"
      if [ "${major}" -eq "${min_major}" ]
      then
         minor="`echo "${version}" | head -1 | cut -d. -f2`"
         if [ "${minor}" -lt "${min_minor}" ]
         then
            arewegood="NO"
         fi
      fi
   fi

   [ "${arewegood}" = "YES" ]
}


assert_version()
{
   local string

   string="$1"
   [ $# -ne 0 ] && shift

   if check_version "$@"
   then
      return
   fi

   echo "version of ${string} is too old" >&2
   exit 1
}


setup_bootstrap()
{
   BOOTSTRAP_LIBEXECPATH="`mulle-bootstrap library-path | head -1`"
   if [ -z "${BOOTSTRAP_LIBEXECPATH}" ]
   then
      cat <<EOF >&2
mulle-bootstrap is not in the PATH.
Test code uses the mulle-bootstrap function library, so
unfortunately we can't continue here.
EOF
      exit 1
   fi


   #
   # this also loads in "logging"
   #
   PATH="${BOOTSTRAP_LIBEXECPATH}:$PATH" . mulle-bootstrap-functions.sh >&2

   assert_version "mulle-bootstrap-functions.sh"         \
                  "${MULLE_BOOTSTRAP_FUNCTIONS_VERSION}" \
                  "${REQUIRED_FUNCTIONS_MIN_MAJOR}"      \
                  "${REQUIRED_FUNCTIONS_MIN_MINOR}"
}



setup_tooling()
{
   case "${UNAME}" in
      mingw)
         CC="`mingw_mangle_compiler_exe "${CC}" "CC"`"
         CXX="`mingw_mangle_compiler_exe "${CXX}" "CXX"`"
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

      "")
         log_fail "UNAME not set"
      ;;

      *)
         CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
         CMAKE="${CMAKE:-cmake}"
         MAKE="${MAKE:-make}"
         CC="${CC:-cc}"
         CXX="${CXX:-c++}"
      ;;
   esac

   case "${CC}" in
      *-cl|*-cl.exe|cl.exe|cl)
         CFLAGS="${DEFAULT_CL_CFLAGS}"
         DEBUG_CFLAGS="${DEBUG_CL_CFLAGS}"
         RELEASE_CFLAGS="${RELEASE_CL_CFLAGS}"
      ;;

      *)
         CFLAGS="${DEFAULT_GCC_CFLAGS}"
         DEBUG_CFLAGS="${DEBUG_GCC_CFLAGS}"
         RELEASE_CFLAGS="${RELEASE_GCC_CFLAGS}"
      ;;
   esac
}


setup_environment()
{
   case "${UNAME}" in
      mingw)
         MULLE_LOG_DEVICE="/dev/stdout"
         SHLIB_PREFIX="${SHLIB_PREFIX}"
         SHLIB_EXTENSION="${SHLIB_EXTENSION:-.lib}" # link with extension
         CRLFCAT="dos2unix"
         ;;

      darwin)
         SHLIB_PREFIX="${SHLIB_PREFIX:-lib}"
         SHLIB_EXTENSION="${SHLIB_EXTENSION:-.dylib}"
         LDFLAGS="-framework Foundation"  ## harmles and sometimes useful
         CRLFCAT="cat"
         ;;

      linux)
         SHLIB_PREFIX="${SHLIB_PREFIX:-lib}"
         SHLIB_EXTENSION="${SHLIB_EXTENSION:-.so}"
         LDFLAGS="-ldl -lpthread"
         CRLFCAT="cat"
         ;;

      "")
         log_fail "UNAME not set"
      ;;

      *)
         SHLIB_PREFIX="${SHLIB_PREFIX:-lib}"
         SHLIB_EXTENSION="${SHLIB_EXTENSION:-.so}"
         CRLFCAT="cat"
         ;;
   esac
 }


setup_bootstrap
setup_environment
setup_tooling
