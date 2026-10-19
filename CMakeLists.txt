cmake_minimum_required( VERSION 3.13...99.99)

project( mulle-test VERSION 7.5.0 LANGUAGES NONE)

execute_process( COMMAND ./mulle-test-env version
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_TEST_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_TEST_VERSION is ${MULLE_TEST_VERSION} according to mulle-test-env")


set( PROJECT_VERSION "${MULLE_TEST_VERSION}")


set( SCRIPTS
mulle-test
mulle-timeout
)


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
)

set( EXTENSIONS
src/mulle-sde
)


#
# FreeBSD test helpers: the real scripts live in libexec (freebsd-vm.sh and
# freebsd-devroot.sh source freebsd-common.sh relative to $0), bin gets thin
# launchers that resolve the prefix at runtime. Keep in sync with bin/installer.
#
file( GLOB FREEBSD_LIBEXEC_SCRIPTS
   "freebsd/*.sh"
   "freebsd/freebsd-run"
)

set( FREEBSD_LAUNCHERS
freebsd-run
freebsd-devroot.sh
freebsd-vm.sh
)

set( FREEBSD_LAUNCHER_FILES "")
foreach( launcher ${FREEBSD_LAUNCHERS})
   file( GENERATE
         OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/freebsd-launchers/${launcher}"
         CONTENT "#!/bin/sh
selfdir=\"\$(CDPATH= cd -- \"\$(dirname -- \"\$0\")\" && pwd -P)\"
prefix=\"\$(CDPATH= cd -- \"\${selfdir}/..\" && pwd -P)\"
exec \"\${prefix}/libexec/mulle-test/freebsd/${launcher}\" \"\$@\"
")
   list( APPEND FREEBSD_LAUNCHER_FILES
 "${CMAKE_CURRENT_BINARY_DIR}/freebsd-launchers/${launcher}"
   )
endforeach()


INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-test")

install( FILES ${FREEBSD_LIBEXEC_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-test/freebsd")

install( PROGRAMS ${FREEBSD_LAUNCHER_FILES}
DESTINATION "bin")

install( DIRECTORY ${EXTENSIONS}
   DESTINATION "share/mulle-sde/extensions"
   USE_SOURCE_PERMISSIONS
   PATTERN "*._DS_Store" EXCLUDE
   PATTERN "*.ignore" EXCLUDE
)

install( FILES "freebsd/FREEBSD-TEST-IN-VM.md"
   DESTINATION "share/mulle-sde/extensions/mulle-sde/c-test-runtime/share/sde/howto"
   RENAME "freebsd-test-in-vm.md"
)

######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
