#!/bin/bash
# -----------------------------------------------------------------------------
# build_genie_mac.sh -- native GENIE (FASER fork, 3.04 or 3.06) build on macOS / Apple Silicon
#
#   1) conda-forge env ~/miniforge3/envs/genie: ROOT, LHAPDF6, GSL, libxml2, log4cpp, compilers
#   2) Pythia 6.4.28      (github.com/alisw/pythia6, tag 428-alice4)
#   3) APFEL 3.0.6        OPTIONAL (WITH_APFEL=1): only needed for GENIE's HEDIS model.
#                          3.0.x still ships libAPFEL.la, which GENIE's configure checks for
#      Pythia8            OPTIONAL (WITH_PYTHIA8=1): conda-forge pythia8, for the
#                          Pythia8Hadro2019 hadronization (Pythia6 is still required)
#   4) TPythia6           (GenieGenerator/faser/TPythia6_standalone)
#   5) GENIE              (after patch_genie_make.sh: macosxarm64 + Pythia6 link fix)
# Everything goes to <work>/install; downloads are cached in <work>/external/downloads,
# where <work> is the directory that contains GenieGenerator/.
#
# Usage:  ./build_genie_mac.sh
#         WITH_PYTHIA8=1 WITH_APFEL=1 ./build_genie_mac.sh     (both default to 0)
#         GENIE_CONDA_ENV, NJ can also be overridden
# -----------------------------------------------------------------------------
set -euo pipefail
_genie_here="${BASH_SOURCE[0]}"
_genie_real="$(readlink -f "${_genie_here}" 2>/dev/null || echo "${_genie_here}")"
SCRIPTS="$( cd "$( dirname "${_genie_real}" )" >/dev/null 2>&1 && pwd )"   # this script + setup_*.sh
if [ -d "${SCRIPTS}/src/make" ]; then                                      # repository top directory
    WORK="$( dirname "${SCRIPTS}" )"; EXT="${SCRIPTS}/faser/build/external"
else                                                                       # work area with GenieGenerator/
    WORK="${SCRIPTS}"; EXT="${SCRIPTS}/GenieGenerator/faser/build/external"
    [ -d "${EXT}" ] || EXT="${SCRIPTS}/external"                            # old 3.04 layout
fi
DL="${WORK}/external/downloads"
BLD_DIR="${WORK}/build"   # not $BUILD: conda activation overwrites that
NJ=${NJ:-$(sysctl -n hw.ncpu)}
mkdir -p "${DL}"
export GENIE_CONDA_ENV=${GENIE_CONDA_ENV:-genie}
WITH_APFEL=${WITH_APFEL:-0}
WITH_PYTHIA8=${WITH_PYTHIA8:-0}

[ "$(uname -s)" = "Darwin" ] || { echo "This script is for macOS; on Linux use build_genie_lcg.sh"; exit 1; }
[ "$(uname -m)" = "arm64" ]  || echo "WARNING: not running natively on arm64 (Rosetta shell?)"
xcrun --show-sdk-path >/dev/null 2>&1 || { echo "Install the Xcode command line tools: xcode-select --install"; exit 1; }

# ---- 1) conda environment ---------------------------------------------------
# We use a private Miniforge (native arm64, conda-forge only, fast mamba/libmamba
# solver) instead of an existing Anaconda: old Anaconda installs use the classic
# solver, which can take hours to solve an environment containing ROOT.
# Installed with -b: it does NOT touch ~/.zshrc or your existing (base) Anaconda.
MINIFORGE=${MINIFORGE:-$HOME/miniforge3}
if [ ! -x "${MINIFORGE}/bin/conda" ]; then
    echo "=== Installing Miniforge into ${MINIFORGE} (one-time, ~1 min)"
    curl -fL --retry 3 -o "${DL}/Miniforge3-MacOSX-arm64.sh" \
        https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh
    bash "${DL}/Miniforge3-MacOSX-arm64.sh" -b -p "${MINIFORGE}"
fi
ENV_PREFIX="${MINIFORGE}/envs/${GENIE_CONDA_ENV}"
if [ ! -d "${ENV_PREFIX}/conda-meta" ]; then
    echo "=== Creating conda env ${ENV_PREFIX} (conda-forge, osx-arm64; a few minutes)"
    _solver="${MINIFORGE}/bin/mamba"; [ -x "${_solver}" ] || _solver="${MINIFORGE}/bin/conda"
    CONDA_SUBDIR=osx-arm64 "${_solver}" create -y -p "${ENV_PREFIX}" \
        -c conda-forge --override-channels \
        root lhapdf gsl libxml2 log4cpp cmake make compilers python
fi
if [ "${WITH_PYTHIA8}" = 1 ] && [ ! -f "${ENV_PREFIX}/include/Pythia8/Pythia.h" ]; then
    echo "=== Adding pythia8 to ${ENV_PREFIX}"
    _solver="${MINIFORGE}/bin/mamba"; [ -x "${_solver}" ] || _solver="${MINIFORGE}/bin/conda"
    CONDA_SUBDIR=osx-arm64 "${_solver}" install -y -p "${ENV_PREFIX}" -c conda-forge --override-channels pythia8
fi
export GENIE_CONDA_PREFIX="${ENV_PREFIX}"

set +u; source "${SCRIPTS}/setup_mac.sh"; set -u
[ "$(root-config --arch)" = "macosxarm64" ] || { echo "ROOT arch is $(root-config --arch), expected macosxarm64"; exit 1; }
mkdir -p "${BLD_DIR}" "${GENIE_INSTALL}"/{bin,lib,include}

# GENIE >= 3.06 links "-lPythia6" (ROOT's historical name for the library).
# Provide that name next to libEGPythia6 unless it already resolves (on the default
# case-insensitive macOS filesystem libpythia6.dylib already matches).
provide_libPythia6() {   # $1 = the real Pythia6 shared library
    local dst="${GENIE_INSTALL}/lib/libPythia6.${1##*.}"
    [ -e "${dst}" ] || ln -s "$1" "${dst}"
}

fetch() {  # url file
    [ -s "${DL}/$2" ] || curl -fL --retry 3 -o "${DL}/$2" "$1"
}
fetch https://github.com/alisw/pythia6/archive/refs/tags/428-alice4.tar.gz pythia6-428-alice4.tar.gz
[ "${WITH_APFEL}" = 1 ] && fetch https://github.com/scarrazza/apfel/archive/refs/tags/3.0.6.tar.gz apfel-3.0.6.tar.gz

# ---- 2) Pythia6 -------------------------------------------------------------
echo "=== Pythia6"
rm -rf "${BLD_DIR}/src/pythia6-428-alice4" "${BLD_DIR}/pythia6"; mkdir -p "${BLD_DIR}/src"
tar xzf "${DL}/pythia6-428-alice4.tar.gz" -C "${BLD_DIR}/src"
cmake -S "${EXT}/pythia6" -B "${BLD_DIR}/pythia6" -DCMAKE_BUILD_TYPE=Release \
      -DPYTHIA6_SRC="${BLD_DIR}/src/pythia6-428-alice4" -DCMAKE_INSTALL_PREFIX="${GENIE_INSTALL}"
cmake --build "${BLD_DIR}/pythia6" -j "${NJ}" && cmake --install "${BLD_DIR}/pythia6"
provide_libPythia6 "${GENIE_INSTALL}/lib/libpythia6.dylib"

# ---- 3) APFEL (optional) ---------------------------------------------------
if [ "${WITH_APFEL}" = 1 ]; then
    echo "=== APFEL"
    rm -rf "${BLD_DIR}/src/apfel-3.0.6"
    tar xzf "${DL}/apfel-3.0.6.tar.gz" -C "${BLD_DIR}/src"
    ( cd "${BLD_DIR}/src/apfel-3.0.6"
      # APFEL 3.0.6 ships 2013 config.sub/config.guess, which do not know "arm64-apple-*"
      # (conda's compiler activation exports build_alias/host_alias=arm64-apple-darwin20.0.0).
      # Use the GNU name for Apple Silicon instead.
      _triplet="aarch64-apple-darwin$(uname -r)"
      env -u build_alias -u host_alias \
          ./configure --prefix="${GENIE_INSTALL}" --disable-pywrap \
                      --build="${_triplet}" --host="${_triplet}"
      # --disable-pywrap is ignored by APFEL 3.0.6's configure.ac: drop it (and docs/examples) by hand
      sed -i.bak -E 's/^(SUBDIRS = .*) pywrap/\1/; s/^(SUBDIRS = .*) examples/\1/; s/^(SUBDIRS = .*) doc/\1/' Makefile
      make -j "${NJ}" && make install )
    [ -f "${GENIE_INSTALL}/lib/libAPFEL.la" ] || { echo "APFEL install failed"; exit 1; }
fi

# ---- 4) TPythia6 ------------------------------------------------------------
echo "=== TPythia6"
rm -rf "${BLD_DIR}/TPythia6"
cmake -S "${GENIE}/faser/TPythia6_standalone" -B "${BLD_DIR}/TPythia6" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH="${CONDA_PREFIX}" -DCMAKE_INSTALL_PREFIX="${TPYTHIA6_PATH}" \
      -DPYTHIA6_LIB="${PYTHIA6_LIB}"
cmake --build "${BLD_DIR}/TPythia6" -j "${NJ}" && cmake --install "${BLD_DIR}/TPythia6"

# ---- 5) GENIE ---------------------------------------------------------------
echo "=== GENIE"
bash "${EXT}/patch_genie_make.sh" "${GENIE}"
cd "${GENIE}"
[ -f src/make/Make.config ] && { make distclean >/dev/null 2>&1 || true; }
GENIE_OPTS=(
    --prefix="${GENIE_INSTALL}"
    --with-compiler=clang
    --enable-faser
    --enable-lhapdf6 --disable-lhapdf5
    --with-lhapdf6-lib="${LHAPDF6_LIB}" --with-lhapdf6-inc="${LHAPDF6_INC}"
    --with-pythia6-lib="${PYTHIA6_LIB}"
    --with-libxml2-lib="${LIBXML2_LIB}" --with-libxml2-inc="${LIBXML2_INC}"
    --with-log4cpp-lib="${LOG4CPP_LIB}" --with-log4cpp-inc="${LOG4CPP_INC}"
)
if [ "${WITH_APFEL}" = 1 ]; then
    GENIE_OPTS+=(--enable-apfel --with-apfel-lib="${APFEL_LIB}" --with-apfel-inc="${APFEL_INC}")
else
    GENIE_OPTS+=(--disable-apfel)
fi
if [ "${WITH_PYTHIA8}" = 1 ]; then
    GENIE_OPTS+=(--enable-pythia8 --with-pythia8-lib="${CONDA_PREFIX}/lib" --with-pythia8-inc="${CONDA_PREFIX}/include")
fi
./configure "${GENIE_OPTS[@]}"
make -j "${NJ}"
make install

echo
echo "Done. In a new terminal:   source ${SCRIPTS}/setup_mac.sh   then e.g.  gevgen_faser --help"
