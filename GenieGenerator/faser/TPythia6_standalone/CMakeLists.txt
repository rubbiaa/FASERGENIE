# -----------------------------------------------------------------------------
# Standalone build of ROOT's old TPythia6 / TPythia6Decayer / TMCParticle
# (removed from ROOT in 6.32). Plain CMake, no Athena/Calypso.
#
# Produces <prefix>/lib/libEGPythia6.{so,dylib} (+ rootmap/pcm) and
#          <prefix>/include/TPythia6/*.h
# which is exactly what GENIE's Make.include expects (-lEGPythia6).
#
#   cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$TPYTHIA6_PATH -DPYTHIA6_LIB=$PYTHIA6_LIB
#   cmake --build build -j && cmake --install build
# -----------------------------------------------------------------------------
cmake_minimum_required(VERSION 3.16)
project(TPythia6 LANGUAGES C CXX)

find_package(ROOT REQUIRED COMPONENTS Core EG Physics)

set(PYTHIA6_LIB "$ENV{PYTHIA6_LIB}" CACHE PATH "Directory containing libpythia6.{so,dylib}")
find_library(PYTHIA6_LIBRARY NAMES pythia6 HINTS ${PYTHIA6_LIB} NO_DEFAULT_PATH)
if(NOT PYTHIA6_LIBRARY)
  message(FATAL_ERROR "libpythia6 not found in PYTHIA6_LIB='${PYTHIA6_LIB}'")
endif()

# The original sources live next door, untouched
set(SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../TPythia6)
set(HDRS TPythia6.h TMCParticle.h TPythia6Decayer.h TPythia6Calls.h)

# Pythia6 pieces: the Fortran library, plus (LCG layout only) a separate
# "root interface" lib with pythia6_common_address / tpythia6_called_from_cc
# and the block-data object pydata.o. Our own macOS build has all in one lib.
set(PYTHIA6_LINK ${PYTHIA6_LIBRARY})
find_library(PYTHIA6_ROOTIF NAMES rootinterface HINTS ${PYTHIA6_LIB} NO_DEFAULT_PATH)
if(PYTHIA6_ROOTIF)
  list(APPEND PYTHIA6_LINK ${PYTHIA6_ROOTIF})
endif()
if(EXISTS ${PYTHIA6_LIB}/pydata.o)
  list(APPEND PYTHIA6_LINK ${PYTHIA6_LIB}/pydata.o)
endif()
message(STATUS "Pythia6 link items: ${PYTHIA6_LINK}")

add_library(EGPythia6 SHARED
  ${SRC_DIR}/src/TMCParticle.cxx
  ${SRC_DIR}/src/TPythia6.cxx
  ${SRC_DIR}/src/TPythia6Decayer.cxx)
target_include_directories(EGPythia6 PUBLIC
  $<BUILD_INTERFACE:${SRC_DIR}/TPythia6>
  $<INSTALL_INTERFACE:include/TPythia6>)
target_link_libraries(EGPythia6 PUBLIC ROOT::Core ROOT::EG ROOT::Physics ${PYTHIA6_LINK})
set_target_properties(EGPythia6 PROPERTIES
  INSTALL_RPATH "${PYTHIA6_LIB}"
  INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib"   # macOS: absolute install name
  MACOSX_RPATH OFF)

# ROOT I/O dictionary (+ rootmap and _rdict.pcm, so ROOT/cling can autoload it)
root_generate_dictionary(G__EGPythia6
  ${HDRS}
  MODULE EGPythia6
  LINKDEF ${CMAKE_CURRENT_SOURCE_DIR}/LinkDef.h)

install(TARGETS EGPythia6 LIBRARY DESTINATION lib)
install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/libEGPythia6_rdict.pcm
  ${CMAKE_CURRENT_BINARY_DIR}/libEGPythia6.rootmap
  DESTINATION lib)
foreach(h ${HDRS})
  install(FILES ${SRC_DIR}/TPythia6/${h} DESTINATION include/TPythia6)
endforeach()
