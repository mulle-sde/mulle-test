cmake_minimum_required( VERSION 3.15)

project( mulle-test VERSION 6.6.1 LANGUAGES NONE)

execute_process( COMMAND ./mulle-test-env version
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_TEST_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_TEST_VERSION is ${MULLE_TEST_VERSION} according to mulle-test-env")


set( PROJECT_VERSION "${MULLE_TEST_VERSION}")


set( SCRIPTS
mulle-test
)


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
)

set( EXTENSIONS
src/mulle-sde
)


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

install( DIRECTORY ${EXTENSIONS}
   DESTINATION "share/mulle-sde/extensions"
   USE_SOURCE_PERMISSIONS
   PATTERN "*._DS_Store" EXCLUDE
   PATTERN "*.ignore" EXCLUDE
)

######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
