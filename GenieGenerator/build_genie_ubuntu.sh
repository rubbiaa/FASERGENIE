#!/bin/bash
# -----------------------------------------------------------------------------
# build_genie_ubuntu.sh -- GENIE (FASER fork) on a plain Ubuntu/Debian machine
#
#   0) checks the apt packages and your ROOT (needs Geom and MathMore)
#   1) LHAPDF 6.5.4       built from source, unless lhapdf-config already exists
#   2) Pythia 6.4.28      (github.com/alisw/pythia6, tag 428-alice4)
#   3) APFEL 3.0.6        OPTIONAL (WITH_APFEL=1): only needed for the HEDIS model
#   4) TPythia6           (GenieGenerator/faser/TPythia6_standalone)
#   5) GENIE              --enable-faser (+ --enable-pythia8 with WITH_PYTHIA8=1 and PYTHIA8=...)
# GENIE goes to <work>/install, the externals to <work>/external/install,
# downloads are cached in <work>/external/downloads, where <work> contains GenieGenerator/.
#
# Usage:  ./build_genie_ubuntu.sh
#         ROOT_THISROOT=/path/bin/thisroot.sh ./build_genie_ubuntu.sh
#         WITH_PYTHIA8=1 PYTHIA8=$HOME/ROOT/pythia8312 ./build_genie_ubuntu.sh
#         NJ=<n> sets the number of parallel jobs
# -----------------------------------------------------------------------------
set -euo pipefail
_genie_here="${BASH_SOURCE[0]}"
_genie_real="$(readlink -f "${_genie_here}" 2>/dev/null || echo "${_genie_here}")"
SCRIPTS="$( cd "$( dirname "${_genie_real}" )" >/dev/null 2>&1 && pwd )"   # this script + setup_*.sh
if [ -d "${SCRIPTS}/src/make" ]; then                                      # repository top directory
    WORK="$( dirname "${SCRIPTS}" )"; EXT="${SCRIPTS}/faser/build/external"
else                                                                       # work area with GenieGenerator/
    WORK="${SCRIPTS}"; EXT="${SCRIPTS}/GenieGenerator/faser/build/external"
fi
DL="${WORK}/external/downloads"
BLD_DIR="${WORK}/build"
NJ=${NJ:-$(nproc)}
WITH_APFEL=${WITH_APFEL:-0}
WITH_PYTHIA8=${WITH_PYTHIA8:-0}
LHAPDF_VERSION=${LHAPDF_VERSION:-6.5.4}

[ "$(uname -s)" = "Linux" ] || { echo "This script is for Linux; on macOS use build_genie_mac.sh"; exit 1; }
if [ -f /etc/os-release ]; then . /etc/os-release; fi
case "${ID:-}${ID_LIKE:-}" in *ubuntu*|*debian*) ;; *) echo "WARNING: not Ubuntu/Debian (${PRETTY_NAME:-unknown}); package names may differ";; esac

# ---- 0) prerequisites ---------------------------------------------------------
missing=()
for pkg in build-essential gfortran cmake libxml2-dev libgsl-dev liblog4cpp5-dev curl; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing system packages: ${missing[*]}"
    echo "Install them with:"
    echo "    sudo apt update && sudo apt install ${missing[*]}"
    exit 1
fi

set +u; source "${SCRIPTS}/setup_ubuntu.sh"; set -u
mkdir -p "${DL}" "${BLD_DIR}/src" "${GENIE_INSTALL}"/{bin,lib,include} "${GENIE_EXT_INSTALL}"/{lib,include}

for lib in Geom MathMore EG; do
    ls "$(root-config --libdir)"/lib${lib}.so >/dev/null 2>&1 || {
        echo "Your ROOT ($(root-config --prefix)) has no lib${lib}.so."
        echo "GENIE needs ROOT built with geometry and MathMore (GSL): -Dgeom=ON -Dmathmore=ON"; exit 1; }
done
echo "ROOT $(root-config --version), C++ flags: $(root-config --cflags | grep -o -- '-std=[^ ]*')"

fetch() {  # url file
    [ -s "${DL}/$2" ] || curl -fL --retry 3 -o "${DL}/$2" "$1"
}
fetch https://github.com/alisw/pythia6/archive/refs/tags/428-alice4.tar.gz pythia6-428-alice4.tar.gz
[ "${WITH_APFEL}" = 1 ] && fetch https://github.com/scarrazza/apfel/archive/refs/tags/3.0.6.tar.gz apfel-3.0.6.tar.gz

# ---- 1) LHAPDF 6 ------------------------------------------------------------
if ! command -v lhapdf-config >/dev/null 2>&1; then
    echo "=== LHAPDF ${LHAPDF_VERSION}"
    fetch "https://lhapdf.hepforge.org/downloads/?f=LHAPDF-${LHAPDF_VERSION}.tar.gz" "LHAPDF-${LHAPDF_VERSION}.tar.gz"
    rm -rf "${BLD_DIR}/src/LHAPDF-${LHAPDF_VERSION}"
    tar xzf "${DL}/LHAPDF-${LHAPDF_VERSION}.tar.gz" -C "${BLD_DIR}/src"
    ( cd "${BLD_DIR}/src/LHAPDF-${LHAPDF_VERSION}"
      ./configure --prefix="${GENIE_EXT_INSTALL}" --disable-python
      make -j "${NJ}" && make install )
    set +u; source "${SCRIPTS}/setup_ubuntu.sh"; set -u      # picks up the new lhapdf-config
else
    echo "=== LHAPDF: using $(command -v lhapdf-config) ($(lhapdf-config --version))"
fi

# ---- 2) Pythia6 -------------------------------------------------------------
echo "=== Pythia6"
rm -rf "${BLD_DIR}/src/pythia6-428-alice4" "${BLD_DIR}/pythia6"
tar xzf "${DL}/pythia6-428-alice4.tar.gz" -C "${BLD_DIR}/src"
cmake -S "${EXT}/pythia6" -B "${BLD_DIR}/pythia6" -DCMAKE_BUILD_TYPE=Release \
      -DPYTHIA6_SRC="${BLD_DIR}/src/pythia6-428-alice4" -DCMAKE_INSTALL_PREFIX="${GENIE_EXT_INSTALL}"
cmake --build "${BLD_DIR}/pythia6" -j "${NJ}" && cmake --install "${BLD_DIR}/pythia6"
# GENIE 3.06 links "-lPythia6" (ROOT's historical name): provide it (Linux is case-sensitive)
[ -e "${GENIE_EXT_INSTALL}/lib/libPythia6.so" ] || ln -s libpythia6.so "${GENIE_EXT_INSTALL}/lib/libPythia6.so"

# ---- 3) APFEL (optional) ------------------------------------------------------
if [ "${WITH_APFEL}" = 1 ]; then
    echo "=== APFEL"
    rm -rf "${BLD_DIR}/src/apfel-3.0.6"
    tar xzf "${DL}/apfel-3.0.6.tar.gz" -C "${BLD_DIR}/src"
    ( cd "${BLD_DIR}/src/apfel-3.0.6"
      ./configure --prefix="${GENIE_EXT_INSTALL}" --disable-pywrap
      # --disable-pywrap is ignored by APFEL 3.0.6's configure.ac: drop it (and docs/examples) by hand
      sed -i -E 's/^(SUBDIRS = .*) pywrap/\1/; s/^(SUBDIRS = .*) examples/\1/; s/^(SUBDIRS = .*) doc/\1/' Makefile
      make -j "${NJ}" && make install )
    [ -f "${GENIE_EXT_INSTALL}/lib/libAPFEL.la" ] || { echo "APFEL install failed"; exit 1; }
fi

# ---- 4) TPythia6 ------------------------------------------------------------
echo "=== TPythia6"
rm -rf "${BLD_DIR}/TPythia6"
cmake -S "${GENIE}/faser/TPythia6_standalone" -B "${BLD_DIR}/TPythia6" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH="${ROOTSYS}" -DCMAKE_INSTALL_PREFIX="${TPYTHIA6_PATH}" \
      -DPYTHIA6_LIB="${PYTHIA6_LIB}"
cmake --build "${BLD_DIR}/TPythia6" -j "${NJ}" && cmake --install "${BLD_DIR}/TPythia6"

# ---- 5) GENIE ---------------------------------------------------------------
echo "=== GENIE"
bash "${EXT}/patch_genie_make.sh" "${GENIE}"     # no-op on Linux for 3.06, kept for 3.04 trees
cd "${GENIE}"
[ -f src/make/Make.config ] && { make distclean >/dev/null 2>&1 || true; }
GENIE_OPTS=(
    --prefix="${GENIE_INSTALL}"
    --with-compiler=gcc
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
    [ -n "${PYTHIA8_LIB:-}" ] || { echo "WITH_PYTHIA8=1 but no Pythia8 found: set PYTHIA8=/path/to/pythia8xxx"; exit 1; }
    GENIE_OPTS+=(--enable-pythia8 --with-pythia8-lib="${PYTHIA8_LIB}" --with-pythia8-inc="${PYTHIA8_INC}")
fi
./configure "${GENIE_OPTS[@]}"
make -j "${NJ}"
make install

echo
echo "Done. In a new shell:   source ${SCRIPTS}/setup_ubuntu.sh   then e.g.  gevgen_faser --help"
