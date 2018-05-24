
set( MULLE_VIRTUAL_ROOT "$ENV{MULLE_VIRTUAL_ROOT}")
if( NOT MULLE_VIRTUAL_ROOT)
   set( MULLE_VIRTUAL_ROOT "${PROJECT_SOURCE_DIR}")
endif()
if( NOT DEPENDENCY_DIR)
   set( DEPENDENCY_DIR "${MULLE_VIRTUAL_ROOT}/dependency")
endif()
if( NOT ADDICTIONS_DIR)
   set( ADDICTIONS_DIR "${MULLE_VIRTUAL_ROOT}/addiction")
endif()
include_directories( BEFORE SYSTEM
${DEPENDENCY_DIR}/include
${ADDICTIONS_DIR}/include
)
set( CMAKE_LIBRARY_PATH "${DEPENDENCY_DIR}/lib"
"${ADDICTIONS_DIR}/lib"
${CMAKE_LIBRARY_PATH}
)
set( CMAKE_FRAMEWORK_PATH "${DEPENDENCY_DIR}/Frameworks"
"${ADDICTIONS_DIR}/Frameworks"
${CMAKE_FRAMEWORK_PATH}
)

set( CMAKE_INCLUDES
"cmake/DependenciesAndLibraries.cmake"
"cmake/_Dependencies.cmake"
"cmake/_Libraries.cmake"
)

set( CMAKE_EDITABLE_FILES
CMakeLists.txt
cmake/HeadersAndSources.cmake
cmake/DependenciesAndLibraries.cmake
)

include( EnvironmentAux OPTIONAL)