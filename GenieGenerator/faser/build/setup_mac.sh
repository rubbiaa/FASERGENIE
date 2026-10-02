# -----------------------------------------------------------------------------
# setup_mac.sh  --  GENIE (FASER fork, 3.04/3.06) environment on macOS / Apple Silicon
#
# Native build: no CVMFS, no container. Dependencies come from a conda-forge
# environment (ROOT, LHAPDF6, GSL, libxml2, log4cpp, clang/gfortran);
# Pythia6, APFEL, TPythia6 and GENIE are built by build_genie_mac.sh into ./install
#
# Usage (zsh or bash):   source setup_mac.sh
#   GENIE_CONDA_ENV=myenv source setup_mac.sh     (default env name: genie)
# -----------------------------------------------------------------------------

if [ -n "${BASH_VERSION:-}" ]; then
    _genie_here="${BASH_SOURCE[0]}"; _genie_sh=bash
elif [ -n "${ZSH_VERSION:-}" ]; then
    eval '_genie_here="${(%):-%x}"'; _genie_sh=zsh
fi
# --- locate the GENIE source tree --------------------------------------------
# Works both when this script sits next to GenieGenerator/ (work-area layout)
# and when it lives inside the repository at GenieGenerator/faser/build/.
_genie_real="$(readlink -f "${_genie_here}" 2>/dev/null || echo "${_genie_here}")"
_genie_dir="$( cd "$( dirname "${_genie_real}" )" >/dev/null 2>&1 && pwd )"
if [ -d "${_genie_dir}/GenieGenerator/src" ]; then
    _genie_src="${_genie_dir}/GenieGenerator"
else
    _genie_src="$( cd "${_genie_dir}/../.." >/dev/null 2>&1 && pwd )"
fi
export GENIE="${_genie_src}"                          # GENIE source tree
export GENIE_HOME="$( dirname "${GENIE}" )"           # work area: install/, build/, run/, faser_xsec/
export GENIE_SCRIPTS="${_genie_dir}"                  # where these scripts (and external/) live
GENIE_CONDA_ENV=${GENIE_CONDA_ENV:-genie}

# --- conda env (created by build_genie_mac.sh in ~/miniforge3/envs/genie) -----
if [ -z "${GENIE_CONDA_PREFIX:-}" ]; then
    for _p in "${MINIFORGE:-$HOME/miniforge3}/envs/${GENIE_CONDA_ENV}" \
              "$HOME/opt/anaconda3/envs/${GENIE_CONDA_ENV}" "$HOME/anaconda3/envs/${GENIE_CONDA_ENV}"; do
        if [ -d "${_p}/conda-meta" ]; then GENIE_CONDA_PREFIX="${_p}"; break; fi
    done
fi
if [ -z "${GENIE_CONDA_PREFIX:-}" ]; then
    echo "setup_mac.sh: ERROR: conda env '${GENIE_CONDA_ENV}' not found -- run ./build_genie_mac.sh first"
    return 1
fi
export GENIE_CONDA_PREFIX
# use the conda that owns the env, so activation scripts (compilers, ROOT) run
_c="${GENIE_CONDA_PREFIX%/envs/*}/bin/conda"
[ -x "${_c}" ] && eval "$("${_c}" shell.${_genie_sh} hook)"
if [ "${CONDA_PREFIX:-}" != "${GENIE_CONDA_PREFIX}" ]; then
    conda activate "${GENIE_CONDA_PREFIX}" || { echo "setup_mac.sh: ERROR: cannot activate ${GENIE_CONDA_PREFIX}"; return 1; }
fi

# --- ROOT --------------------------------------------------------------------
export ROOTSYS="${ROOTSYS:-$(root-config --prefix)}"    # GENIE's configure insists on it

# --- GENIE locations -----------------------------------------------------------
export GENIE_INSTALL="${GENIE_HOME}/install"          # GENIE + Pythia6 + APFEL + TPythia6
export TPYTHIA6_PATH="${GENIE_INSTALL}"

# --- dependency paths for GENIE's ./configure ---------------------------------
export PYTHIA6_LIB="${GENIE_INSTALL}/lib";  export PYTHIA6="${PYTHIA6_LIB}"
export APFEL_LIB="${GENIE_INSTALL}/lib";    export APFEL_INC="${GENIE_INSTALL}/include"
export LHAPDF6_LIB="${CONDA_PREFIX}/lib";   export LHAPDF6_INC="${CONDA_PREFIX}/include"
export LOG4CPP_LIB="${CONDA_PREFIX}/lib";   export LOG4CPP_INC="${CONDA_PREFIX}/include"
export LIBXML2_LIB="${CONDA_PREFIX}/lib";   export LIBXML2_INC="${CONDA_PREFIX}/include/libxml2"

# --- compilers: hand conda's clang to GENIE's Make.include (see patch_genie_make.sh)
export GENIE_CXX="${CXX:-clang++}"
export GENIE_CC="${CC:-clang}"
# drop -dead_strip_dylibs: GENIE links with -undefined dynamic_lookup, so "unused"
# dylibs (e.g. libEGPythia6) would otherwise be stripped and fail at run time
export GENIE_LDFLAGS="$(echo "${LDFLAGS:-}" | sed 's/-Wl,-dead_strip_dylibs//g')"
export ENV_CXXFLAGS="${CXXFLAGS:-}"

# --- PDFs: GENIE ships its own LHAPDF sets ----------------------------------
export LHAPATH="${GENIE}/data/evgen/pdfs"
export LHAPDF_DATA_PATH="${GENIE}/data/evgen/pdfs:${CONDA_PREFIX}/share/LHAPDF"

# --- TPythia6 ------------------------------------------------------------------
export LINUX_SYS_INCLUDES="-I${TPYTHIA6_PATH}/include/TPythia6"
export SYSLIBS="-L${TPYTHIA6_PATH}/lib"

# --- run-time paths ----------------------------------------------------------
# Libraries are built with absolute install names, so executables do not need
# DYLD_LIBRARY_PATH; ROOT_LIBRARY_PATH lets ROOT macros (convertGHEP.C) autoload
# GENIE/TPythia6 libraries, and it survives macOS SIP (DYLD_* does not).
export PATH="${GENIE_INSTALL}/bin:${PATH}"
export ROOT_LIBRARY_PATH="${GENIE_INSTALL}/lib${ROOT_LIBRARY_PATH:+:${ROOT_LIBRARY_PATH}}"
export DYLD_LIBRARY_PATH="${GENIE_INSTALL}/lib${DYLD_LIBRARY_PATH:+:${DYLD_LIBRARY_PATH}}"
export ROOT_INCLUDE_PATH="${GENIE_INSTALL}/include/GENIE:${TPYTHIA6_PATH}/include/TPythia6${ROOT_INCLUDE_PATH:+:${ROOT_INCLUDE_PATH}}"

echo "GENIE env (macOS): conda env ${GENIE_CONDA_PREFIX}, ROOT $(root-config --version), arch $(root-config --arch)"
echo "  GENIE         = ${GENIE}"
echo "  GENIE_INSTALL = ${GENIE_INSTALL}"
unset _genie_here _genie_sh _c _p _genie_real _genie_dir _genie_src
