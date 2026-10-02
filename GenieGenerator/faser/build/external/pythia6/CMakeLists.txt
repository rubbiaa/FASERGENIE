# -----------------------------------------------------------------------------
# Pythia 6.4.28 as one shared library (libpythia6.so / libpythia6.dylib)
# Sources: https://github.com/alisw/pythia6 (tag 428-alice4) = Lund pythia-6.4.28.f
#          + ROOT's pythia6_common_address.c / tpythia6_called_from_cc.F
# The whole Fortran file is one object, so BLOCK DATA PYDATA is always linked
# in (no separate pydata.o needed).
#
#   cmake -S . -B build -DPYTHIA6_SRC=/path/to/pythia6-428-alice4 \
#         -DCMAKE_INSTALL_PREFIX=/path/to/prefix
# -----------------------------------------------------------------------------
cmake_minimum_required(VERSION 3.16)
project(pythia6 LANGUAGES C Fortran)

set(PYTHIA6_SRC "" CACHE PATH "Directory with pythia-6.4.28.f etc.")
if(NOT EXISTS "${PYTHIA6_SRC}/pythia-6.4.28.f")
  message(FATAL_ERROR "pythia-6.4.28.f not found in PYTHIA6_SRC='${PYTHIA6_SRC}'")
endif()

# MAIN() stub some linkers want for Fortran-only shared libs
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/main_stub.c "void MAIN__(void) {}\n")

add_library(pythia6 SHARED
  ${PYTHIA6_SRC}/pythia-6.4.28.f
  ${PYTHIA6_SRC}/tpythia6_called_from_cc.F
  ${PYTHIA6_SRC}/pythia6_common_address.c
  ${CMAKE_CURRENT_BINARY_DIR}/main_stub.c)

# Pythia6 is legacy F77: no implicit-none, old-style DATA, etc.
target_compile_options(pythia6 PRIVATE
  $<$<COMPILE_LANGUAGE:Fortran>:-O2 -fno-second-underscore -std=legacy -w>)

# absolute install name on macOS -> executables find it without DYLD_LIBRARY_PATH
set_target_properties(pythia6 PROPERTIES
  INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib"
  MACOSX_RPATH OFF)

install(TARGETS pythia6 LIBRARY DESTINATION lib)
