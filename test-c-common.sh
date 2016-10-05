SOURCE_EXTENSION=".c"
STANDALONE_SUFFIX="_standalone"

OPTIMIZED_GCC_CFLAGS="-w -O3 -g"
DEBUG_GCC_CFLAGS="-w -O0 -g"

# http://stackoverflow.com/questions/3007312/resolving-lnk4098-defaultlib-msvcrt-conflicts-with
# we link vs. cmake generated stuff, that is usually a DLL or will be wrapped into a DLL
# so we compile with /MD
RELEASE_CL_CFLAGS="-O2 -MD -wd4068" #-/W /O0"
DEBUG_CL_CFLAGS="-Zi -DEBUG -MDd -Od -wd4068" #-/W /O0"
