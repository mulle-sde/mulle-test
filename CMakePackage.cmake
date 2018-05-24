#
# CPack and project specific stuff
#
######

set( CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set( CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set( CPACK_PACKAGE_CONTACT "Nat! <nat@mulle-kybernetik.de>")
set( CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/README.md")
set( CPACK_PACKAGE_DESCRIPTION_SUMMARY "☑︎ Runs tests and compares results against expectations ")
set( CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
set( CPACK_STRIP_FILES false)


set( CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://github.com/mulle-nat/mulle-test")
set( CPACK_DEBIAN_PACKAGE_DEPENDS "mulle-make", "mulle-bashfunctions", "cmake (>= 3.0.0)")
set( CPACK_RPM_PACKAGE_VENDOR "Mulle kybernetiK")

