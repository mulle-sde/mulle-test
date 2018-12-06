#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_TEST_ENVIRONMENT_SH="included"


# this is crap and needs some kind of plugin interface

setup_language()
{
   log_entry "setup_language" "$@"

   local platform="$1"
   local language="${2:-c}"
   local dialect="${3:-c}"

   case "${language}" in
      c)
         case "${dialect}" in
            c)
               PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-c}"
               STANDALONE_SUFFIX="-standalone"

               OPTIMIZED_GCC_CFLAGS="-w -O3 -g"
               DEBUG_GCC_CFLAGS="-w -O0 -g"

               # http://stackoverflow.com/questions/3007312/resolving-lnk4098-defaultlib-msvcrt-conflicts-with
               # we link vs. cmake generated stuff, that is usually a DLL or will be wrapped into a DLL
               # so we compile with /MD
               RELEASE_CL_CFLAGS="-O2 -MD -wd4068" #-/W /O0"
               DEBUG_CL_CFLAGS="-Zi -DEBUG -MDd -Od -wd4068" #-/W /O0"
            ;;

            objc)
               case "${dialect}" in
                  Apple|GNUStep)
                  ;;

                  *)
                     case "${platform}" in
                        mingw*)
                           CC="mulle-clang-cl"
                           CXX="mulle-clang-cl"

                           # nmake doesn't work ? /questionable!
                           MAKE="make"
                        ;;

                        darwin)
                           APPLE_SDKPATH="`xcrun --show-sdk-path`"
                           [ -z "${APPLE_SDKPATH}" ] && fail "Could not figure out sdk path with xcrun"

                           CC="mulle-clang"
                           CXX="mulle-clang"
                        ;;

                        *)
                           CC="mulle-clang"
                           CXX="mulle-clang"
                        ;;
                     esac
                  ;;
               esac

               PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-m:aam}"
               STANDALONE_SUFFIX="-standalone"

               RELEASE_GCC_CFLAGS="-w -O3 -g"
               DEBUG_GCC_CFLAGS="-w -O0 -g"

               RELEASE_CL_CFLAGS="-O2  -MD -wd4068" #-/W /O0"
               DEBUG_CL_CFLAGS="-Od -MDd -wd4068" #-/W /O0"
            ;;

            *)
               fail "unsupported \"${language}\" dialect \"${dialect}\""
            ;;
         esac
      ;;

      *)
         fail "unsupported language \"${language}\""
      ;;
   esac
}


setup_library_type()
{
   log_entry "setup_library_type" "$@"

   local libtype="${1:-standalone}"

   case "${libtype}" in
      "shared")
         [ -z "${SHAREDLIB_PREFIX}"    ] && fail "SHAREDLIB_PREFIX undefined"
         [ -z "${SHAREDLIB_EXTENSION}" ] && fail "SHAREDLIB_EXTENSION undefined"

         LIB_PREFIX="${SHAREDLIB_PREFIX}"
         LIB_EXTENSION="${SHAREDLIB_EXTENSION}"
         LIB_SUFFIX="${LIB_SUFFIX}"
         return
      ;;

      "standalone")
         [ -z "${SHAREDLIB_PREFIX}"    ] && fail "SHAREDLIB_PREFIX undefined"
         [ -z "${SHAREDLIB_EXTENSION}" ] && fail "SHAREDLIB_EXTENSION undefined"
         [ -z "${STANDALONE_SUFFIX}"   ] && fail "STANDALONE_SUFFIX undefined"

         LIB_PREFIX="${SHAREDLIB_PREFIX}"
         LIB_EXTENSION="${SHAREDLIB_EXTENSION}"
         LIB_SUFFIX="${STANDALONE_SUFFIX}"
         return
      ;;

      "static")
         [ -z "${STATICLIB_EXTENSION}" -a -z "${STATICLIB_PREFIX}" ] && fail "STATICLIB variables undefined"

         LIB_PREFIX="${STATICLIB_PREFIX}"
         LIB_EXTENSION="${STATICLIB_EXTENSION}"
         LIB_SUFFIX="${LIB_SUFFIX}"
      ;;

      *)
         fail "unsupported library type \"$1\""
      ;;
   esac
}


setup_tooling()
{
   log_entry "setup_tooling" "$@"

   local platform="$1"

   case "$1" in
      mingw)
         CC="`mingw_mangle_compiler_exe "${CC}" "CC"`"
         CXX="`mingw_mangle_compiler_exe "${CXX}" "CXX"`"
         CMAKE="${CMAKE:-cmake}"
         MAKE="${MAKE:-nmake}"

         case "${MAKE}" in
            nmake)
               CMAKE_GENERATOR="NMake Makefiles"
            ;;

            make|ming32-make|"")
               CC="${CC:-cl}"
               CXX="${CXX:-cl}"
               CMAKE="mulle-mingw-cmake.sh"
               MAKE="mulle-mingw-make.sh"
               CMAKE_GENERATOR="MinGW Makefiles"
               FILEPATH_DEMANGLER="mingw_demangle_path"
            ;;

            *)
               CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
            ;;
         esac
      ;;

      "")
         fail "platform not set"
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
         DEBUG_CFLAGS="${DEBUG_CL_CFLAGS}"
         RELEASE_CFLAGS="${RELEASE_CL_CFLAGS}"
      ;;

      *)
         DEBUG_CFLAGS="${DEBUG_GCC_CFLAGS}"
         RELEASE_CFLAGS="${RELEASE_GCC_CFLAGS}"
      ;;
   esac
}


setup_platform()
{
   log_entry "setup_platform" "$@"

   local platform="$1"

   #
   # for purposes of .gitignore and sublime it is easier to have a .exe
   # extensions on all platforms:
   #
   EXE_EXTENSION=".exe"
   DEBUG_EXE_EXTENSION=".debug.exe"

   case "${platform}" in
      mingw)
         SHAREDLIB_PREFIX=""
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.lib}" # link with extension
         STATICLIB_PREFIX=""
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.lib}" # link with extension
         ;;

      darwin)
         SHAREDLIB_PREFIX="lib"
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.dylib}" # link with extension
         STATICLIB_PREFIX="lib"
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.a}" # link with extension
         ;;

      *)
         SHAREDLIB_PREFIX="lib"
         SHAREDLIB_EXTENSION="${SHAREDLIB_EXTENSION:-.so}" # link with extension
         STATICLIB_PREFIX="lib"
         STATICLIB_EXTENSION="${STATICLIB_EXTENSION:-.a}" # link with extension
      ;;
   esac


   case "${platform}" in
      mingw)
         CRLFCAT="dos2unix"
      ;;

      darwin)
         case "${CC}" in
            mulle-cl*)
               # do nuthing
            ;;

            *)
               LDFLAGS="${LDFLAGS} -framework Foundation"  ## harmles and sometimes useful
            ;;
         esac
         CRLFCAT="cat"
      ;;

      linux)
         LDFLAGS="${LDFLAGS} -ldl -lpthread"  # weak and lame
         CRLFCAT="cat"
      ;;

      "")
         log_fail "platform not set"
      ;;

      *)
         CRLFCAT="cat"
      ;;
   esac
}


setup_library()
{
   log_entry "setup_library" "$@"

   #
   # Find the standalone .so file we need for the tests
   #
   local platform="$1"
   local library_file="$2"
   local required="$3"

   LIBRARY_FILE="${library_file}"
   if [ -z "${LIBRARY_FILE}" ]
   then
      local library_filename

      [ -z "${PROJECT_NAME}" ] && fail "PROJECT_NAME not set"

      library_filename="${LIB_PREFIX}${PROJECT_NAME}${LIB_SUFFIX}${LIB_EXTENSION}"
      r_locate_library "${library_filename}" "${LIBRARY_FILE}"
      LIBRARY_FILE="${RVAL}"

      if [ -z "${LIBRARY_FILE}" ]
      then
         if [ "${required}" = "YES" ]
         then
            log_error "error: ${library_filename} can not be found."

            log_info "Maybe you have not run \"build-test.sh\" yet ?

You commonly need a shared library target in your CMakeLists.txt that
links in all the platform dependencies for your platform. This library
should be installed into \"./lib\" (and headers into \"./include\").

By convention a \"build-test.sh\" script does this using the
\"CMakeLists.txt\" file of your project."

            exit 1
         else
            log_fluff "Library \"${library_filename}\" not found, but not required"
         fi
      fi
   fi

   local library_dir

   if [ -z "${LIBRARY_FILE}" ]
   then
      library_dir="${PWD}/bin"
      LIBRARY_INCLUDE="${PWD}/include"
   else
      r_absolutepath "${LIBRARY_FILE}"
      LIBRARY_FILE="${RVAL}"

      local library_root

      #
      # figure out where the headers are
      #
      r_fast_dirname "${LIBRARY_FILE}"
      library_dir="${RVAL}"

      r_fast_dirname "${library_dir}"
      library_root="${RVAL}"
      if [ -d "${library_root}/usr/local/include" ]
      then
         LIBRARY_INCLUDE="${library_root}/usr/local/include"
      else
         LIBRARY_INCLUDE="${library_root}/include"
      fi
   fi

   case "${platform}" in
      darwin)
         RPATH_FLAGS="-Wl,-rpath ${library_dir}"

         log_verbose "RPATH_FLAGS=${RPATH_FLAGS}"
      ;;

      linux)
         r_colon_concat "${library_dir}" "${LD_LIBRARY_PATH}"
         LD_LIBRARY_PATH="${RVAL}"

         log_verbose "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
      ;;

      mingw*)
         r_colon_concat "${library_dir}" "${PATH}"
         PATH="${PATH}"

         log_verbose "PATH=${PATH}"
      ;;

      *)
         log_warning "Unknown platform \"${platform}\", shared library might \
not be found"
   esac


   #
   # manage additional libraries, expected to be in same path as library
   #
   local i
   local add_library_file
   local filename
   local RVAL

   IFS="
"
   for i in ${ADDITIONAL_LIBS}
   do
      IFS="${DEFAULT_IFS}"

      filename="${LIB_PREFIX}${i}${LIB_SUFFIX}${LIB_EXTENSION}"
      r_locate_library "${filename}" || exit 1
      add_library_file="${RVAL}"
      r_absolutepath "${add_library_file}"
      add_library_file="${RVAL}"

      log_verbose "Additional library: ${add_library_file}"
      r_colon_concat "${ADDITIONAL_LIBRARY_FILES}" "${add_library_file}"
      ADDITIONAL_LIBRARY_FILES="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"

   #
   # read os-specific-libraries, to link
   #
   local os_specific

   os_specific="${LIBRARY_INCLUDE}/${PROJECT_NAME}/link/os-specific-libraries.txt"

   if [ -f "${os_specific}" ]
   then
      IFS="
"
      for path in `egrep -v '^#' "${os_specific}"`
      do
         IFS="${DEFAULT_IFS}"

         log_verbose "Additional library: ${path}"
         r_colon_concat "${ADDITIONAL_LIBRARY_FILES}" "${path}"
         ADDITIONAL_LIBRARY_FILES="${RVAL}"
      done
      IFS="${DEFAULT_IFS}"
   else
      log_warning "${os_specific} not found"
   fi
}


setup_environment()
{
   log_entry "setup_environment" "$@"

   local platform="$1"

   #
   #
   #
   RESTORE_CRASHDUMP=`suppress_crashdumping`
   trap 'trace_ignore "${RESTORE_CRASHDUMP}"' 0 5 6

   #
   #
   #
   MAKEFLAGS="${MAKEFLAGS:-${DEFAULT_MAKEFLAGS}}"

   #
   # Find debugger, clear variable if not installed
   #
   DEBUGGER="${DEBUGGER:-`command -v mulle-lldb`}"
   DEBUGGER="${DEBUGGER:-`command -v gdb`}"
   DEBUGGER="${DEBUGGER:-`command -v lldb`}"

   #
   # Some lazy shortcuts, to allow mulle-test to run outside of mulle-sde
   # (sometimes)
   #
   if [ -z "${PROJECT_DIR}" ]
   then
      PROJECT_DIR="`fast_dirname "${PWD}"`"
      log_fluff "PROJECT_DIR assumed to be \"${PROJECT_DIR}\""

      if [ -z "${DEPENDENCY_DIR}" -a -d "${PROJECT_DIR}/dependency" ]
      then
         DEPENDENCY_DIR="${PROJECT_DIR}/dependency"
         log_fluff "DEPENDENCY_DIR assumed to be \"${DEPENDENCY_DIR}\""
      fi
      if [ -z "${ADDICTION_DIR}" -a -d "${PROJECT_DIR}/addiction" ]
      then
         ADDICTION_DIR="${PROJECT_DIR}/addiction"
         log_fluff "ADDICTION_DIR assumed to be \"${ADDICTION_DIR}\""
      fi
   fi

   if [ -z "${PROJECT_NAME}" ]
   then
      r_fast_basename "${PROJECT_DIR}"
      PROJECT_NAME="${RVAL}"
      PROJECT_NAME="${PROJECT_NAME%%.*}"

      log_fluff "PROJECT_NAME assumed to be \"${PROJECT_NAME}\""
   fi

   if [ -z "${PROJECT_LANGUAGE}" ]
   then
      PROJECT_LANGUAGE="c"
      log_fluff "PROJECT_LANGUAGE assumed to be \"c\""
   fi

   if [ -z "${CC}" ]
   then
      fail "CC for C compiler not defined"
   fi

   assert_binary "$CC" "CC"
}


include_required()
{
   log_entry "include_required" "$@"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"
   fi

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-environment.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-mingw.sh"

   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-cmake.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-compiler.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-execute.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-flagbuilder.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-locate.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-logging.sh"
   . "${MULLE_TEST_LIBEXEC_DIR}/mulle-test-regexsearch.sh"
}


setup_project()
{
   log_entry "setup_project" "$@"

   local platform="$1"

   setup_language "${platform}" "${PROJECT_LANGUAGE}" "${PROJECT_DIALECT}"
   setup_tooling "${platform}"
   setup_platform "${platform}" # after tooling
}


setup_user()
{
   log_entry "setup_user" "$@"

   local platform="$1"

   setup_library_type "${LIBRARY_TYPE}"
   setup_environment "${platform}"

   local envfile

   envfile=".mulle-test/etc/environment.sh"
   if [ -f "${envfile}" ]
   then
      . "${envfile}" || fail "\"${envfile}\" read failed"
      log_fluff "Read environment file \"${envfile}\" "
   fi
}
