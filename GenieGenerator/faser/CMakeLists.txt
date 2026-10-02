cmake_minimum_required(VERSION 3.10)
# suppress warning and unwanted behavior
set(CMAKE_POLICY_DEFAULT_CMP0074 NEW)
file( READ ${CMAKE_SOURCE_DIR}/version.txt _version )
string( STRIP ${_version} _version )
project( Calypso VERSION ${_version} LANGUAGES C CXX Fortran )
unset( _version )

set( ATLAS_PROJECT Athena
   CACHE STRING	   "The name of the project to build against" )

find_package( Athena )

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

atlas_ctest_setup()

atlas_project( USE ${ATLAS_PROJECT} ${${ATLAS_PROJECT}_VERSION} )

lcg_generate_env( SH_FILE ${CMAKE_BINARY_DIR}/${ATLAS_PLATFORM}/env_setup.sh )
install( FILES ${CMAKE_BINARY_DIR}/${ATLAS_PLATFORM}/env_setup.sh
 DESTINATION . )
