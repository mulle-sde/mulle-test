#!/usr/bin/env bash
#  run-test.sh
#  MulleObjC
#
#  Created by Nat! on 01.11.13.
#  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
#  (was run-mulle-scion-test)

set -m # job control enable

#
# this is system wide, not so great
# and also not trapped...
#
suppress_crashdumping()
{
   local restore

   case "${UNAME}" in
      darwin)
         restore="`defaults read com.apple.CrashReporter DialogType 2> /dev/null`"
         defaults write com.apple.CrashReporter DialogType none
         ;;
   esac

   echo "${restore}"
}


restore_crashdumping()
{
   local restore

   restore="$1"

   case "${UNAME}" in
      darwin)
         if [ -z "${restore}" ]
         then
            defaults delete com.apple.CrashReporter DialogType
         else
            defaults write com.apple.CrashReporter DialogType "${restore}"
         fi
         ;;
   esac
}


trace_ignore()
{
   restore_crashdumping "$1"
   return 0
}


#
#
#
maybe_show_diagnostics()
{
   local errput

   errput="$1"

   local contents
   contents="`head -2 "${errput}"`" 2> /dev/null
   if [ "${contents}" != "" ]
   then
      log_info "DIAGNOSTICS:" >&2
      cat "${errput}" >&2
   fi
}


maybe_show_output()
{
   local output

   output="$1"

   local contents
   contents="`head -2 "${output}"`" 2> /dev/null
   if [ "${contents}" != "" ]
   then
      log_info "OUTPUT:"
      cat  "${output}"
   fi
}


search_for_strings()
{
   local errput
   local strings
   local banner

   banner="$1"
   errput="$2"
   strings="$3"

   local fail
   local expect
   local match

   fail=0
   while read expect
   do
      if [ ! -z "$expect" ]
      then
         match=`exekutor grep "$expect" "${errput}"`
         if [ "$match" = "" ]
         then
            if [ $fail -eq 0 ]
            then
               log_error "${banner}" >&2
               fail=1
            fi
            echo "   $expect" >&2
         fi
      fi
   done < "$strings"

   return $fail
}

#
# more specialized exekutors
#
#
# also redirects error to output (for tests)
#
err_redirect_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      "$@" > "${output}" 2>&1
   fi
}


redirect_eval_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      eval "$@" > "${output}"
   fi
}


full_redirekt_eval_exekutor()
{
   local stdin
   local stdout
   local stderr

   stdin="$1"
   shift
   stdout="$1"
   shift
   stderr="$1"
   shift

   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" "<" "${stdin}" ">" "${stdout}" ">" "${stderr}" >&2
      else
         echo "==>" "$@" "<" "${stdin}" ">" "${stdout}" ">" "${stderr}" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      eval "$@" < "${stdin}" > "${stdout}" 2> "${stderr}"
   fi
}


fail_test_generic()
{
   local sourcefile
   local a_out
   local stdin
   local ext

   sourcefile="$1"
   a_out_ext="$2"
   stdin="$3"
   ext="$4"

   if [ -z "${MULLE_TEST_IGNORE_FAILURE}" ]
   then
      exit 1
   fi
}


suggest_debugger_commandline()
{
   local a_out_ext
   local stdin

   a_out_ext="$1"
   stdin="$2"

   case "${UNAME}" in
      darwin)
         echo "MULLE_OBJC_AUTORELEASEPOOL_TRACE=15 \
MULLE_OBJC_TEST_ALLOCATOR=1 \
MULLE_TEST_ALLOCATOR_TRACE=2 \
MallocStackLogging=1 \
MALLOC_FILL_SPACE=1 \
DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib \
DYLD_FALLBACK_LIBRARY_PATH=\"${DYLD_FALLBACK_LIBRARY_PATH}\" \
LD_LIBRARY_PATH=\"${LD_LIBRARY_PATH}:${DEBUGGER_LIBRARY_PATH}\" ${DEBUGGER} ${a_out_ext}" >&2
         if [ "${stdin}" != "/dev/null" ]
         then
            echo "run < ${stdin}" >&2
         fi
      ;;
   esac
}


fail_test_makefile()
{
   local sourcefile
   local a_out
   local stdin
   local ext

   sourcefile="$1"
   a_out_ext="$2"
   stdin="$3"
   ext="$4"

   if [ -z "${MULLE_TEST_IGNORE_FAILURE}" ]
   then
      log_info "DEBUG: " >&2
      log_info "rebuilding as `basename -- ${a_out_ext}` with -O0 and debug symbols..."

      eval_exekutor CFLAGS="${DEBUG_CFLAGS} -I${LIBRARY_INCLUDE} -I${DEPENDENCIES_INCLUDE} -I${ADDICTIONS_INCLUDE}" \
      LDFLAGS="${LDFLAGS} ${LIBRARY_PATH}" \
      OUTPUT="${a_out_ext}" make -B

      suggest_debugger_commandline "${a_out_ext}" "${stdin}"
      exit 1
   fi
}


fail_test_c()
{
   local sourcefile
   local a_out
   local stdin
   local ext

   sourcefile="$1"
   a_out_ext="$2"
   stdin="$3"
   ext="$4"

   if [ -z "${MULLE_TEST_IGNORE_FAILURE}" ]
   then
      log_info "DEBUG: "
      log_info "rebuilding as `basename -- ${a_out_ext}` with -O0 and debug symbols..."

      exekutor "${CC}" ${DEBUG_CFLAGS} -o "${a_out_ext}" \
         "-I${LIBRARY_INCLUDE}" \
         "-I${DEPENDENCIES_INCLUDE}" \
         "-I${ADDICTIONS_INCLUDE}" \
         ${LDFLAGS} \
         "${LIBRARY_PATH}" \
         "${sourcefile}" 

      suggest_debugger_commandline "${a_out_ext}" "${stdin}"

      exit 1
   fi
}


run_makefile_test()
{
   local srcfile
   local owd
   local a_out_ext

   case "${UNAME}" in
      mingw)
         log_error "Can't do Makefile test on MINGW (yet?) ($2)"
         return
      ;;
   esac

   srcfile="$1"
   owd="$2"
   a_out_ext="$3"

   eval_exekutor CC="${CC}" \
   CFLAGS="${CFLAGS} -I${LIBRARY_INCLUDE} -I${DEPENDENCIES_INCLUDE} -I${ADDICTIONS_INCLUDE}" \
   LDFLAGS="${LDFLAGS} ${LIBRARY_PATH}" \
   OUTPUT="${a_out_ext}" ${MAKE} -B
}


run_gcc_compiler()
{
   local srcfile
   local owd
   local a_out_ext
   local errput

   srcfile="$1"
   owd="$2"
   a_out_ext="$3"
   errput="$4"

   err_redirect_exekutor "${errput}" "${CC}" ${CFLAGS} -o "${a_out_ext}" \
   "-I${LIBRARY_INCLUDE}" \
   "-I${DEPENDENCIES_INCLUDE}" \
   "-I${ADDICTIONS_INCLUDE}" \
   "${sourcefile}" \
   "${LIBRARY_PATH}" \
   ${LDFLAGS}  
}


run_cl_compiler()
{
   local srcfile
   local owd
   local a_out_ext
   local errput

   srcfile="$1"
   owd="$2"
   a_out_ext="$3"
   errput="$4"

   local l_include
   local l_path
   local d_include
   local a_include

   l_include="`mingw_demangle_path "${LIBRARY_INCLUDE}"`"
   l_path="`mingw_demangle_path "${LIBRARY_PATH}"`"
   d_include="`mingw_demangle_path "${DEPENDENCIES_INCLUDE}"`"
   a_include="`mingw_demangle_path "${ADDICTIONS_INCLUDE}"`"
   a_out_ext="`mingw_demangle_path "${a_out_ext}"`"

   err_redirect_exekutor "${errput}" "${CC}" ${CFLAGS} "/Fe${a_out_ext}" \
   "/I ${l_include}" \
   "/I ${d_include}" \
   "/I ${a_include}" \
   "${sourcefile}" \
   "${l_path}" \
   ${LDFLAGS} 
}


run_compiler()
{
   case "${CC}" in
      cl|cl.exe|*-cl|*-cl.exe)
         run_gcc_compiler "$@"  #mingw magic
      ;;

      *)
         run_gcc_compiler "$@"
      ;;
   esac
}


run_a_out()
{
   local input
   local output
   local errput
   local a_out_ext

   input="$1"
   output="$2"
   errput="$3"
   a_out_ext="$4"

   if [ ! -x "${a_out_ext}" ]
   then
      log_error "Compiler unexpectedly did not produce ${a_out_ext}"
      return 1
   fi

   case "${UNAME}" in
      darwin)
         full_redirekt_eval_exekutor "${input}" "${output}" "${errput}" MULLE_OBJC_TEST_ALLOCATOR=1 \
MallocStackLogging=1 \
MallocScribble=1 \
MallocPreScribble=1 \
MallocGuardEdges=1 \
MallocCheckHeapEach=1 \
         "${a_out_ext}"
      ;;

      *)
         full_redirekt_eval_exekutor "${input}" "${output}" "${errput}" MULLE_OBJC_TEST_ALLOCATOR=1 "${a_out_ext}"
      ;;
   esac
}


check_compiler_output()
{
   local ccdiag
   local errput
   local pretty_source
   local rval

   ccdiag="$1"
   errput="$2"
   rval="$3"
   pretty_source="$4"

   if [ ${rval} -eq 0 ]
   then
      return 0
   fi

   if [ "${ccdiag}" = "-" ]
   then
      log_error "COMPILER ERRORS: \"${pretty_source}\""
   else
      search_for_strings "COMPILER FAILED TO PRODUCE ERRORS: \"${pretty_source}\" (${errput})" \
                         "${errput}" "${ccdiag}"
      if [ $? -eq 0 ]
      then
         return 3
      fi
   fi

   FAILS=`expr "$FAILS" + 1`

   maybe_show_diagnostics "${errput}"
   if [ -z "${MULLE_TEST_IGNORE_FAILURE}" ]
   then
      exit 1
   fi
   return 1
}


_check_test_output()
{
   local a_out_ext
   local ext
   local stdout
   local errput
   local output
   local errors
   local rval
   local pretty_source

   stdout="$1"
   stderr="$2"
   errors="$3"
   output="$4"
   errput="$5"
   rval="$6"
   pretty_source="$7"
   a_out_ext="$8"
   ext="$9"

   if [ ${rval} -ne 0 ]
   then
      if [ ! -f "${errors}" ]
      then
         log_error "TEST CRASHED: \"${pretty_source}\" (${a_out_ext}, ${errput})"
         return 1
      fi

      search_for_strings "TEST FAILED TO PRODUCE ERRORS: \"${pretty_source}\" (${errput})" \
                         "${errput}" "${errors}"
      if [ $? -eq 0 ]
      then
         # OK!
         return 3  # but don't run a_out_ext
      fi
      return 1
   fi

   if [ -f "${errors}" ]
   then
      log_error "TEST FAILED TO CRASH: \"${pretty_source}\" (${a_out_ext})"
      return 1
   fi

   if [ "${stdout}" != "-" ]
   then
      local result

      result=`exekutor diff -q "${stdout}" "${output}"`
      if [ "${result}" != "" ]
      then
         white=`exekutor diff -q -w "${stdout}" "${output}"`
         if [ "$white" != "" ]
         then
            log_error "FAILED: \"${pretty_source}\" produced unexpected output"
            log_info  "DIFF: (${output} vs. ${stdout})"
            exekutor diff -y "${output}" "${stdout}" >&2
         else
            log_error "FAILED: \"${pretty_source}\" produced different whitespace output"
            log_info  "DIFF: (${stdout} vs. ${output})"
            redirect_exekutor "${output}.actual.hex" od -a "${output}" 
            redirect_exekutor "${output}.expect.hex" od -a "${stdout}" 
            exekutor diff -y "${output}.expect.hex" "${output}.actual.hex" >&2
         fi

         return 2
      fi
   else
      local contents

      contents="`exekutor head -2 "${output}"`" 2> /dev/null
      if [ "${contents}" != "" ]
      then
         log_warning "WARNING: \"${pretty_source}\" produced unexpected output (${output})" >&2
         return 2
      fi
   fi

   if [ "${stderr}" != "-" ]
   then
      result=`exekutor diff "${stderr}" "${errput}"`
      if [ "${result}" != "" ]
      then
         log_warning "WARNING: \"${pretty_source}\" produced unexpected diagnostics (${errput})" >&2
         exekutor echo "" >&2
         exekutor diff "${stderr}" "${errput}" >&2
         return 1
      fi
   fi
}


check_test_output()
{
   local errput
   local output

   output="$4"
   errput="$5"

   local rval

   _check_test_output "$@"
   rval=$?

   if [ $rval -ne 0 ]
   then
      FAILS=`expr "$FAILS" + 1`
      maybe_show_diagnostics "${errput}"
   fi

   if [ ${rval} -gt 1 ]
   then
      maybe_show_output "${output}"
   fi

   return $rval
}


#
# this function defines some quasi-global variables
# and does some other stuff, it's hackish but....
#
#    output
#    errput
#    errors
#    owd
#    pretty_source
#
__preamble()
{
   local sourcefile
   local root
   local ext

   sourcefile="$1"
   root="$2"
   ext="$3"

   local random

   RUNS=`expr "$RUNS" + 1`
   random=`mktemp -t "${LIBRARY_SHORTNAME}.XXXX"`
   output="${random}.stdout"
   errput="${random}.stderr"
   cc_errput="${random}.ccerr"
   errors="`basename -- "${sourcefile}" "${ext}"`.errors"

   owd="`pwd -P`"
   pretty_source=`relative_path_between "${owd}"/"${sourcefile}" "${root}"`

   log_verbose "${pretty_source}"
}


run_common_test()
{
   local a_out
   local sourcefile
   local ext
   local root
   local stdin
   local stdout
   local stderr
   local ccdiag

   a_out="$1"
   sourcefile="$2"
   root="$3"
   ext="$4"
   stdin="$5"
   stdout="$6"
   stderr="$7"
   ccdiag="$8"

   local output
   local cc_errput
   local errput
   local random
   local fail
   local match
   local pretty_source

   __preamble "${sourcefile}" "${root}" "${ext}"

   # plz2shutthefuckup bash
   set +m
   set +b
   set +v
   # denied, will always print TRACE/BPT

   local rval

   local a_out_ext

   a_out_ext="${a_out}${EXE_EXTENSION}"
 
   "${TEST_BUILDER}" "${srcfile}" "${owd}" "${a_out_ext}" "${cc_errput}"
   rval=$?

   check_compiler_output "${ccdiag}" "${cc_errput}" "${rval}" "${pretty_source}"
   rval=$?

   if [ $rval -ne 0 ]
   then
      if [ $rval -eq 3 ]
      then
         return 0
      fi
      return $rval
   fi

   run_a_out "${stdin}" "${output}.tmp" "${errput}.tmp" "${a_out_ext}" 
   rval=$?

   redirect_eval_exekutor "${output}" "${CRLFCAT}" "<" "${output}.tmp"
   redirect_eval_exekutor "${errput}" "${CRLFCAT}" "<" "${errput}.tmp" 
   exekutor rm "${output}.tmp" "${errput}.tmp"

   check_test_output  "${stdout}" \
                      "${stderr}" \
                      "${errors}" \
                      "${output}" \
                      "${errput}" \
                      "${rval}"   \
                      "${pretty_source}" \
                      "${a_out_ext}" \
                      "${ext}"
   rval=$?

   if [ "${rval}" -ne 0 ]
   then
      a_out_ext="${a_out}${DEBUG_EXE_EXTENSION}"

      "${FAIL_TEST}" "${sourcefile}" "${a_out_ext}" "${stdin}" "${ext}"
   fi
   return $rval
}


run_makefile_test()
{
   local sourcefile

   sourcefile="$1"

   local a_out
   local owd

   owd="`pwd -P`"
   a_out="${owd}/${sourcefile}"

   TEST_BUILDER=run_makefile
   FAIL_TEST=fail_test_makefile
   run_common_test "${a_out}" "$@"
}


run_c_test()
{
   local sourcefile
   local ext

   sourcefile="$1"
   ext="$3"

   local a_out
   local owd

   owd="`pwd -P`"
   a_out="${owd}/`basename -- "${sourcefile}" "${ext}"`"

   TEST_BUILDER=run_compiler
   FAIL_TEST=fail_test_c
   run_common_test "${a_out}" "$@"
}


run_m_test()
{
   run_c_test "$@"
}


run_cpp_test()
{
   log_error "$1: cpp testing is not available yet"
}


run_test()
{
   local sourcefile
   local root
   local ext
   local makefile

   sourcefile="$1"
   root="$2"
   ext="$3"

   local stdin
   local stdout
   local stderr
   local plist

   stdin="$1.stdin"
   if [ ! -f "${stdin}" ]
   then
      stdin="provide/$1.stdin"
   fi
   if [ ! -f "${stdin}" ]
   then
      stdin="default.stdin"
   fi
   if [ ! -f "${stdin}" ]
   then
      stdin="/dev/null"
   fi

   stdout="$1.stdout"
   if [ ! -f "${stdout}" ]
   then
      stdout="expect/$1.stdout"
   fi
   if [ ! -f "${stdout}" ]
   then
      stdout="default.stdout"
   fi
   if [ ! -f "${stdout}" ]
   then
      stdout="-"
   fi

   stderr="$1.stderr"
   if [ ! -f "${stderr}" ]
   then
      stderr="expect/$1.stderr"
   fi
   if [ ! -f "${stderr}" ]
   then
      stderr="default.stderr"
   fi
   if [ ! -f "${stderr}" ]
   then
      stderr="-"
   fi

   ccdiag="$1.ccdiag"
   if [ ! -f "${ccdiag}" ]
   then
      ccdiag="expect/$1.ccdiag"
   fi
   if [ ! -f "${ccdiag}" ]
   then
      ccdiag="default.ccdiag"
   fi
   if [ ! -f "${ccdiag}" ]
   then
      ccdiag="-"
   fi

   if [ -z "${sourcefile}" ]
   then
      sourcefile="`basename -- "${PWD}"`"
   else
      sourcefile="${sourcefile}${ext}"
   fi

   case "${ext}" in
      Makefile)
         run_makefile_test "$sourcefile" "${root}" "${ext}" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
         ;;

      .m|.aam)
         run_m_test "$sourcefile" "${root}" "${ext}" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
         ;;

      .c)
         run_c_test "$sourcefile" "${root}" "${ext}" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
         ;;

      .cxx|.cpp)
         run_cpp_test "$sourcefile" "${root}" "${ext}" "${stdin}" "${stdout}" "${stderr}" "${ccdiag}"
         ;;
   esac
}


scan_current_directory()
{
   local root

   root="$1"

   local i
   local filename
   local owd

   if [ -f Makefile ]
   then
      run_test "" "${root}" "Makefile"
      return 0
   fi

   old="${IFS:- }"
   IFS="
"

   for i in `ls -1`
   do
      IFS="${old}"

      case "${i}" in
         _*|build|include|lib|bin|tmp|etc|share)
         ;;

         *)
            if [ -d "${i}" ]
            then
               owd="`pwd -P`"
               cd "${i}"
               scan_current_directory "${root}"
               cd "${owd}"
            else
               for ext in ${SOURCE_EXTENSION}
               do
                  filename=`basename -- "${i}" "${ext}"`
                  if [ "$filename" != "${i}" ]
                  then
                     run_test "${filename}" "${root}" "${ext}"
                     break
                  fi
               done
            fi
         ;;
      esac
   done

   IFS="${old}"
}


assert_binary()
{
   local bin

   bin="`which_binary "$1"`"
   if [ -z "$bin" ]
   then
      fail "$1 can not be found"
   fi
}


#####################################################################
# main
#
# if you really want to you can also specify the LIB_EXTENSION as
# .a, and then pass in the link dependencies as LDFLAGS. But is i
# easier, than a shared library ?
#
usage()
{
   cat <<EOF >&2
usage:
   run-test.sh [options] [tests]

   Options:
         -q  : quiet
         -t  : shell trace
         -v  : verbose

   tests specify source test file
EOF
   exit 1
}


run_named_test()
{
   local directory
   local found
   local filename
   local name
   local old
   local ext

   directory=`dirname -- "$1"`
   filename=`basename -- "$1"`
   found="NO"

   if [ -d "${1}" ]
   then
      cd "${1}"
      scan_current_directory "`pwd -P`"
      return
   fi

   if [ ! -f "${1}" ]
   then
      fail "error: source file not found"
   fi

   for ext in ${SOURCE_EXTENSION}
   do
      name=`basename -- "${filename}" "${ext}"`

      if [ "${name}" != "${filename}" ]
      then
        found="YES"
        break
      fi
   done

   if [ "${found}" = "NO" ]
   then
      fail "error: source file must have ${SOURCE_EXTENSION} extension"
   fi

   old="`pwd -P`"

      cd "${directory}" || exit 1
      run_test "${name}" "${old}" "${ext}"
      rval=$?

   cd "${old}" || exit 1
   exit ${rval}
}


run_all_tests()
{
   local directory

   directory=${1:-`pwd`}
   [ $# -ne 0 ] && shift

   cd "${directory}"
   scan_current_directory "`pwd -P`"

   if [ "$RUNS" -ne 0 ]
   then
      if [ "${FAILS}" -eq 0 ]
      then
         log_info "All tests ($RUNS) passed successfully" >&2
      else
         log_error "$FAILS tests out of $RUNS failed" >&2
      fi
   else
      log_warning "No tests found"
   fi
}


main()
{
   CFLAGS="${CFLAGS:-${RELEASE_CFLAGS}}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -v|--verbose)
            MULLE_BOOTSTRAP_VERBOSE="YES"
         ;;

         -vv)
            MULLE_BOOTSTRAP_FLUFF="YES"
            MULLE_BOOTSTRAP_VERBOSE="YES"
         ;;

         -vvv)
            MULLE_BOOTSTRAP_FLUFF="YES"
            MULLE_BOOTSTRAP_VERBOSE="YES"
            MULLE_EXECUTOR_TRACE="YES"
         ;;

         -V)
            MULLE_EXECUTOR_TRACE="YES"
         ;;

         -n)
            MULLE_EXECUTOR_DRY_RUN="YES"
         ;;

         -f)
            MULLE_TEST_IGNORE_FAILURE="YES"
         ;;

         --debug)
            CFLAGS="${DEBUG_CFLAGS}"
         ;;

         --release)
            CFLAGS="${RELEASE_CFLAGS}"
         ;;

         -t|--trace)
            set -x
         ;;

         -*)
            log_error "unknown option \"$1\""
            usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   if [ -z "${DEBUGGER}" ]
   then
      DEBUGGER=lldb
   fi

   DEBUGGER="`which "${DEBUGGER}" 2> /dev/null`"

   if [ -z "${DEBUGGER_LIBRARY_PATH}" ]
   then
      DEBUGGER_LIBRARY_PATH="`dirname -- "${DEBUGGER}"`/../lib"
   fi


   RESTORE_CRASHDUMP=`suppress_crashdumping`
   trap 'trace_ignore "${RESTORE_CRASHDUMP}"' 0 5 6

   [ -z "${LIBRARY_SHORTNAME}" ] && fail "LIBRARY_SHORTNAME not set"

   LIBRARY_FILENAME="${LIB_PREFIX}${LIBRARY_SHORTNAME}${LIB_SUFFIX}${LIB_EXTENSION}"
   DEPENDENCIES_INCLUDE="../dependencies/include"
   ADDICTIONS_INCLUDE="../addictions/include"

   if [ -z "${LIBRARY_PATH}" ]
   then
      if [ ! -z "${LIB_PATH}" ]
      then
         LIBRARY_PATH="`ls -1 "${LIB_PATH}/${LIBRARY_FILENAME}" 2> /dev/null | tail -1`"
      fi

      if [ ! -f "${LIBRARY_PATH}" ]
      then
         LIBRARY_PATH="`ls -1 "./lib/${LIBRARY_FILENAME}" 2> /dev/null | tail -1`"
      fi

      if [ ! -f "${LIBRARY_PATH}" ]
      then
         LIBRARY_PATH="`ls -1 "../lib/${LIBRARY_FILENAME}" 2> /dev/null | tail -1`"
      fi

      if [ ! -f "${LIBRARY_PATH}" ]
      then
         LIBRARY_PATH="`ls -1 "../dependencies/lib/${LIBRARY_FILENAME}" 2> /dev/null | tail -1`"
      fi

      if [ ! -f "${LIBRARY_PATH}" ]
      then
         LIBRARY_PATH="`ls -1 "../addictions/lib/${LIBRARY_FILENAME}" 2> /dev/null | tail -1`"
      fi

      if [ ! -f "${LIBRARY_PATH}" ]
      then
         LIBRARY_PATH="`ls -1 "./build/Products/Debug/${LIBRARY_FILENAME}" 2> /dev/null | tail -1`"
      fi

      if [ ! -f "${LIBRARY_PATH}" ]
      then
         LIBRARY_PATH="`ls -1 "../build/Products/Debug/${LIBRARY_FILENAME}" 2> /dev/null | tail -1`"
      fi
   fi

   if [ -z "${LIBRARY_PATH}" ]
   then
      log_error "error: ${LIBRARY_FILENAME} can not be found."

      log_info "Maybe you have not run \"build-test.sh\" yet ?

You commonly need a shared library target in your CMakeLists.txt that
links in all the platform dependencies for your platform. This library
should be installed into \"./lib\" (and headers into \"./include\").

By convention a \"build-test.sh\" script does this using the
\"CMakeLists.txt\" file of your project."
      exit 1
   fi

   #
   # figure out where the headers are
   #
   LIBRARY_FILENAME="`basename -- "${LIBRARY_PATH}"`"
   LIBRARY_DIR="`dirname -- "${LIBRARY_PATH}"`"
   LIBRARY_ROOT="`dirname -- "${LIBRARY_DIR}"`"

   if [ -d "${LIBRARY_ROOT}/usr/local/include" ]
   then
      LIBRARY_INCLUDE="${LIBRARY_INCLUDE}/usr/local/include"
   else
      LIBRARY_INCLUDE="${LIBRARY_ROOT}/include"
   fi

   LIBRARY_PATH="`absolutepath "$LIBRARY_PATH"`"
   LIBRARY_INCLUDE="`absolutepath "$LIBRARY_INCLUDE"`"
   DEPENDENCIES_INCLUDE="`absolutepath "$DEPENDENCIES_INCLUDE"`"
   ADDICTIONS_INCLUDE="`absolutepath "$ADDICTIONS_INCLUDE"`"

   LIBRARY_DIR="`dirname -- ${LIBRARY_PATH}`"

   case "${UNAME}" in
      darwin)
         DYLD_FALLBACK_LIBRARY_PATH="${LIBRARY_DIR}"
         export DYLD_FALLBACK_LIBRARY_PATH
      ;;

      linux)
         LD_LIBRARY_PATH="${LIBRARY_DIR}"
         export LD_LIBRARY_PATH
      ;;

      mingw*)
         PATH="${PATH}:${LIBRARY_DIR}"
         export PATH
      ;;
   esac


   if [ -z "${CC}" ]
   then
      fail "CC for C compiler not defined"
   fi

   CCPATH="`which_binary "${CC}"`"
   assert_binary "$CCPATH"

   HAVE_WARNED="NO"
   RUNS=0
   FAILS=0

   if [ "$RUN_ALL" = "YES" -o $# -eq 0 ]
   then
      MULLE_BOOTSTRAP_VERBOSE="${MULLE_BOOTSTRAP_VERBOSE:-YES}"
      run_all_tests "$@"
   else
      while [ $# -ne 0 ]
      do
         run_named_test "$1"
         shift
      done
   fi
}

main "$@"
