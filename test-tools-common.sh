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

      *)
         compiler="cl.exe"
         echo "Using default compiler cl" >&2
      ;;
   esac
   echo "${compiler}"
}


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

