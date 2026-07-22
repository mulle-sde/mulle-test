cmake_minimum_required( VERSION 3.13)

project( test C)

add_executable( test
   dummy.c
)
set_target_properties( test
   PROPERTIES
   SUFFIX ".exe"
)

install( TARGETS test
   RUNTIME DESTINATION "bin"
)
