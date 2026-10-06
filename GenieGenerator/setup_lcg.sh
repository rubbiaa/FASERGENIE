#!/bin/bash
# -----------------------------------------------------------------------------
# setup_lcg.sh  --  GENIE (FASER fork, 3.04/3.06) environment from a plain LCG view
#
# Replaces: ATLAS_container.sh, .asetup.save, kk, and the environment part of
#           GenieGenerator/faser/setupGenerator.sh
# Needs:    an EL9 machine with /cvmfs/sft.cern.ch (e.g. lxplus). No ATLAS,
#           no Athena, no apptainer.
#
# Usage:    source setup_lcg.sh
#           LCG_VERSION=LCG_108 LCG_PLATFORM=x86_64-el9-gcc14-opt source setup_lcg.sh
# -----------------------------------------------------------------------------

LCG_VERSION=${LCG_VERSION:-LCG_107}
case "${LCG_VERSION}" in [0-9]*) LCG_VERSION="LCG_${LCG_VERSION}";; esac   # LCG views export LCG_VERSION=107
LCG_PLATFORM=${LCG_PLATFORM:-x86_64-el9-gcc13-opt}
LCG_VIEW=/cvmfs/sft.cern.ch/lcg/views/${LCG_VERSION}/${LCG_PLATFORM}

if [ ! -f "${LCG_VIEW}/setup.sh" ]; then
    echo "setup_lcg.sh: ERROR: ${LCG_VIEW}/setup.sh not found (is /cvmfs/sft.cern.ch mounted?)"
    return 1 2>/dev/null || exit 1
fi
source "${LCG_VIEW}/setup.sh"
export ROOTSYS="${ROOTSYS:-$(root-config --prefix)}"   # GENIE's configure insists on it

# --- GENIE locations ---------------------------------------------------------
_genie_here="${BASH_SOURCE[0]}"
# --- locate the GENIE source tree --------------------------------------------
# Normally this script sits in the top directory of the GENIE repository; it also
# works from a work area that contains GenieGenerator/ (e.g. through a symlink).
_genie_real="$(readlink -f "${_genie_here}" 2>/dev/null || echo "${_genie_here}")"
_genie_dir="$( cd "$( dirname "${_genie_real}" )" >/dev/null 2>&1 && pwd )"
if [ -d "${_genie_dir}/src/make" ]; then
    _genie_src="${_genie_dir}"                          # repository top directory
else
    _genie_src="${_genie_dir}/GenieGenerator"           # work-area layout
fi
export GENIE="${_genie_src}"                          # GENIE source tree
export GENIE_HOME="$( dirname "${GENIE}" )"           # work area: install/, build/, data/, output/, faser_xsec/
# gevgen_faser writes its .ghep.root / .gfaser.root / status files here (override: --output-dir)
export GENIE_OUTPUT="${GENIE_OUTPUT:-${GENIE_HOME}/output}"
mkdir -p "${GENIE_OUTPUT}" 2>/dev/null
unset _genie_here _genie_real _genie_dir _genie_src
export GENIE_INSTALL="${GENIE_HOME}/install"          # GENIE only (wiped by "make distclean")
export GENIE_EXT_INSTALL="${GENIE_HOME}/external/install"   # TPythia6 (+ libPythia6 link)
export TPYTHIA6_PATH="${GENIE_EXT_INSTALL}"

# --- resolve the real package directories behind the view -------------------
# (the view flattens everything into ${LCG_VIEW}/lib; for Pythia6 we need the
#  real directory because GENIE links the pythia*.o block-data objects there)
_lcg_pkgdir() {   # $1 = a file in ${LCG_VIEW}/lib -> prints its package lib dir
    local f="${LCG_VIEW}/lib/$1"
    [ -e "$f" ] && dirname "$(readlink -f "$f")"
}

export PYTHIA6_LIB=$(_lcg_pkgdir libpythia6.so)
export PYTHIA6="${PYTHIA6_LIB}"                       # GENIE configure picks this up
export LHAPDF6_LIB=$(_lcg_pkgdir libLHAPDF.so)
export LHAPDF6_INC="${LHAPDF6_LIB%/lib*}/include"
export APFEL_LIB=$(_lcg_pkgdir libAPFEL.so)
export APFEL_INC="${APFEL_LIB%/lib*}/include"
export PYTHIA8_LIB=$(_lcg_pkgdir libpythia8.so)
export PYTHIA8_INC="${PYTHIA8_LIB%/lib*}/include"
export LOG4CPP_LIB=$(_lcg_pkgdir liblog4cpp.so)
export LOG4CPP_INC="${LOG4CPP_LIB%/lib*}/include"
export LIBXML2_LIB="${LCG_VIEW}/lib"
export LIBXML2_INC="${LCG_VIEW}/include/libxml2"

for v in PYTHIA6_LIB LHAPDF6_LIB LOG4CPP_LIB; do
    if [ -z "${!v}" ] || [ ! -d "${!v}" ]; then
        echo "setup_lcg.sh: WARNING: $v not found in ${LCG_VIEW} -- try another LCG_VERSION"
    fi
done
unset -f _lcg_pkgdir

# --- PDFs: GENIE ships its own LHAPDF sets ----------------------------------
export LHAPATH="${GENIE}/data/evgen/pdfs"
export LHAPDF_DATA_PATH="${GENIE}/data/evgen/pdfs:${LHAPDF_DATA_PATH}"

# --- TPythia6 (our own build, ROOT >= 6.32 no longer ships it) ---------------
export LINUX_SYS_INCLUDES="-I${TPYTHIA6_PATH}/include/TPythia6"
export SYSLIBS="-L${TPYTHIA6_PATH}/lib"

# --- run-time paths ------------------------------------------------------------
export PATH="${GENIE_INSTALL}/bin:${PATH}"
export LD_LIBRARY_PATH="${GENIE_INSTALL}/lib:${GENIE_EXT_INSTALL}/lib:${PYTHIA6_LIB}:${LD_LIBRARY_PATH}"
# GENIE's Make.include uses an undefined $(PYTHIA_DIR) for -L, so help the linker:
export LIBRARY_PATH="${GENIE_EXT_INSTALL}/lib:${PYTHIA6_LIB}:${LCG_VIEW}/lib:${LIBRARY_PATH}"
export ROOT_INCLUDE_PATH="${TPYTHIA6_PATH}/include/TPythia6:${ROOT_INCLUDE_PATH}"

echo "GENIE env: ${LCG_VERSION} / ${LCG_PLATFORM}, ROOT $(root-config --version 2>/dev/null)"
echo "  GENIE         = ${GENIE}"
echo "  GENIE_INSTALL = ${GENIE_INSTALL}"
echo "  PYTHIA6_LIB   = ${PYTHIA6_LIB}"
