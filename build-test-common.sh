#! /usr/bin/env bash


build_it()
{
   DEPENDENCY_DIR="`mulle-bootstrap paths dependencies`"

   #
   # need mulle-build 3.9 for this to work
   # --no-clean removed

   local prefix

   prefix="`pwd`"
   cmdline="mulle-build -install --build-dir build --prefix '${prefix}'"

   #
   # only let it bootstrap, if dependencies are required and not present
   #
   if [ -z "${DEPENDENCY_DIR}" -o -d "${DEPENDENCY_DIR}" ]
   then
      cmdline="${cmdline} --no-bootstrap"
   fi

   if [ ! -z "${BUILD_OPTIONS}" ]
   then
      cmdline="${cmdline} ${BUILD_OPTIONS}"
   fi

   if [ ! -z "${AUX_BUILD_OPTIONS}" ]
   then
      cmdline="${cmdline} ${AUX_BUILD_OPTIONS}"
   fi

   while [ $# -ne 0 ]
   do
      cmdline="${cmdline} '$1'"
      shift
   done

   eval_exekutor "${cmdline}"
}


main()
{
   local AUX_BUILD_OPTIONS="-f"
   local BUILD_OPTIONS=

   while [ $# -ne 0 ]
   do
      case "$1" in
         -v|--verbose)
            MULLE_FLAG_LOG_VERBOSE="YES"
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
         ;;

         -vv)
            MULLE_FLAG_LOG_FLUFF="YES"
            MULLE_FLAG_LOG_VERBOSE="YES"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
         ;;

         -vvv)
            MULLE_TEST_TRACE_LOOKUP="YES"
            MULLE_FLAG_LOG_FLUFF="YES"
            MULLE_FLAG_LOG_VERBOSE="YES"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
         ;;

         -V)
            MULLE_FLAG_LOG_EXEKUTOR="YES"
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
         ;;

         -s|--silent)
            MULLE_FLAG_LOG_TERSE="YES"
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
         ;;

         -t|--trace)
            set -x
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
         ;;

         --no-clean)
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
            AUX_BUILD_OPTIONS=
         ;;

         --*)
            BUILD_OPTIONS="`concat "${BUILD_OPTIONS}" "$1"`"
         ;;

         -*)
            fail "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   build_it
}

MULLE_EXECUTABLE="`basename -- $0`"
MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE}"
MULLE_EXECUTABLE_PID=$$
main "$@"
