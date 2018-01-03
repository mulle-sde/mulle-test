cmake_minimum_required (VERSION 3.0)

project( mulle-test NONE)

execute_process( COMMAND ./mulle-test-env version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_TEST_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_TEST_VERSION is ${MULLE_TEST_VERSION} according to mulle-test-env")


set( PROJECT_VERSION "${MULLE_TEST_VERSION}")


set( SCRIPTS
mulle-test-env
mulle-test
)


set( LIBRARY_SCRIPTS
src/build-test-common.sh
src/run-test-common.sh
src/test-c-common.sh
src/test-m-common.sh
src/test-sharedlib-common.sh
src/test-staticlib-common.sh
src/test-tools-common.sh
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
DESTINATION "libexec/mulle-test/${PROJECT_VERSION}")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.txt)
include( CPack)
