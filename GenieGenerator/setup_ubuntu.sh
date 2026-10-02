# -----------------------------------------------------------------------------
# setup_ubuntu.sh  --  GENIE (FASER fork) environment on a plain Ubuntu/Debian machine
#
# No conda, no CVMFS, no container. Uses:
#   - your own ROOT build (found automatically, or ROOT_THISROOT=/path/bin/thisroot.sh)
#   - system packages from apt: gfortran cmake libxml2-dev libgsl-dev liblog4cpp5-dev
#   - LHAPDF 6, Pythia6, TPythia6 (and APFEL) built by build_genie_ubuntu.sh
#     into <work>/external/install, unless LHAPDF is already installed (lhapdf-config)
#   - optionally your own Pythia8 build (PYTHIA8=/path, used with WITH_PYTHIA8=1)
#
# Usage (bash or zsh):   source setup_ubuntu.sh
# -----------------------------------------------------------------------------

if [ -n "${BASH_VERSION:-}" ]; then
    _genie_here="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    eval '_genie_here="${(%):-%x}"'
fi

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
export GENIE_HOME="$( dirname "${GENIE}" )"           # work area: install/, build/, run/, faser_xsec/
unset _genie_here _genie_real _genie_dir _genie_src

export GENIE_INSTALL="${GENIE_HOME}/install"          # GENIE only (wiped by "make distclean")
export GENIE_EXT_INSTALL="${GENIE_HOME}/external/install"   # LHAPDF, Pythia6, TPythia6, APFEL
export TPYTHIA6_PATH="${GENIE_EXT_INSTALL}"

# --- ROOT --------------------------------------------------------------------
# Order: ROOT_THISROOT, a ROOT already set up from a self-built install, the newest
# ~/ROOT/root_install*/bin/thisroot.sh, ~/root, /opt/root, /usr/local.
# A snap ROOT (/snap/...) is only a last resort: it is confined and not meant to be
# linked against, so a self-built ROOT found above always wins over it.
_root_cfg="$(command -v root-config 2>/dev/null)"
case "${_root_cfg}" in /snap/*) _root_cfg="";; esac
if [ -n "${ROOT_THISROOT:-}" ] || [ -z "${_root_cfg}" ]; then
    for _f in "${ROOT_THISROOT:-}" \
              $(find "$HOME/ROOT" -maxdepth 3 -path "*/root_install*/bin/thisroot.sh" 2>/dev/null | sort -V -r) \
              "$HOME"/root/bin/thisroot.sh "$HOME"/root_install/bin/thisroot.sh \
              /opt/root/bin/thisroot.sh /usr/local/bin/thisroot.sh; do
        if [ -n "${_f}" ] && [ -f "${_f}" ]; then
            unset ROOTSYS
            . "${_f}"; echo "setup_ubuntu.sh: ROOT from ${_f}"; break
        fi
    done
    unset _f
fi
unset _root_cfg
if ! command -v root-config >/dev/null 2>&1; then
    echo "setup_ubuntu.sh: ERROR: ROOT not found. Source your thisroot.sh first, or"
    echo "                 export ROOT_THISROOT=/path/to/root/bin/thisroot.sh"
    return 1 2>/dev/null || exit 1
fi
case "$(command -v root-config)" in
    /snap/*) echo "setup_ubuntu.sh: WARNING: using the snap ROOT ($(command -v root-config)); GENIE may not link"
             echo "                 against it -- build ROOT yourself or set ROOT_THISROOT";;
esac
export ROOTSYS="$(root-config --prefix)"

# --- system libraries (apt) -----------------------------------------------------
_multiarch="$(gcc -print-multiarch 2>/dev/null)"; _multiarch="${_multiarch:-x86_64-linux-gnu}"
export LIBXML2_INC=/usr/include/libxml2
export LIBXML2_LIB="/usr/lib/${_multiarch}"
export LOG4CPP_INC=/usr/include
# gcc always searches /usr/local/include before /usr/include (and drops -I/usr/include),
# so an old log4cpp 1.0 in /usr/local/include (not valid C++17) shadows the apt one.
# Point GENIE at the apt headers through a small shim directory, which -I puts first.
if grep -qsE 'throw *\(std::invalid_argument\)' /usr/local/include/log4cpp/Priority.hh \
   && [ -d /usr/include/log4cpp ]; then
    _shim="${GENIE_HOME}/external/install/include/log4cpp-system"
    mkdir -p "${_shim}" 2>/dev/null && { [ -e "${_shim}/log4cpp" ] || ln -s /usr/include/log4cpp "${_shim}/log4cpp"; }
    [ -e "${_shim}/log4cpp/Category.hh" ] && export LOG4CPP_INC="${_shim}"
    unset _shim
fi
export LOG4CPP_LIB="/usr/lib/${_multiarch}"
unset _multiarch

# --- LHAPDF 6: a system/user installation if there is one, else ours -----------
# Exception: an old log4cpp (1.0, with dynamic exception specifications, not valid
# C++17) in /usr/local/include. A system LHAPDF in /usr/local puts -I/usr/local/include
# on GENIE's compile line, and since gcc ignores -I/usr/include (a system directory)
# that old log4cpp would shadow the apt one. In that case we build our own LHAPDF
# (GENIE_SYSTEM_LHAPDF=1 forces the system one anyway).
unset GENIE_BUILD_LHAPDF
_old_log4cpp=0
grep -qsE 'throw *\(std::invalid_argument\)' /usr/local/include/log4cpp/Priority.hh && _old_log4cpp=1
if [ -x "${GENIE_EXT_INSTALL}/bin/lhapdf-config" ]; then
    export PATH="${GENIE_EXT_INSTALL}/bin:${PATH}"
fi
_lh_sys=0
if command -v lhapdf-config >/dev/null 2>&1; then
    _lh_sys=1
    if [ "$(lhapdf-config --incdir)" = /usr/local/include ] && [ "${_old_log4cpp}" = 1 ] \
       && [ "${GENIE_SYSTEM_LHAPDF:-0}" != 1 ]; then
        echo "setup_ubuntu.sh: NOTE: old log4cpp in /usr/local/include would break the build with the"
        echo "                 LHAPDF in /usr/local: using our own LHAPDF in ${GENIE_EXT_INSTALL}"
        _lh_sys=0
    fi
fi
if [ "${_lh_sys}" = 1 ]; then
    export LHAPDF6_LIB="$(lhapdf-config --libdir)"
    export LHAPDF6_INC="$(lhapdf-config --incdir)"
else
    export LHAPDF6_LIB="${GENIE_EXT_INSTALL}/lib"     # filled by build_genie_ubuntu.sh
    export LHAPDF6_INC="${GENIE_EXT_INSTALL}/include"
    [ -f "${LHAPDF6_INC}/LHAPDF/LHAPDF.h" ] || export GENIE_BUILD_LHAPDF=1
fi
export GENIE_OLD_LOG4CPP_USRLOCAL="${_old_log4cpp}"
unset _lh_sys _old_log4cpp

# --- Pythia6 / APFEL (ours) -------------------------------------------------------
export PYTHIA6_LIB="${GENIE_EXT_INSTALL}/lib";  export PYTHIA6="${PYTHIA6_LIB}"
export APFEL_LIB="${GENIE_EXT_INSTALL}/lib";    export APFEL_INC="${GENIE_EXT_INSTALL}/include"

# --- Pythia8 (optional, your own build) -----------------------------------------
if [ -z "${PYTHIA8:-}" ]; then
    PYTHIA8="$(find "$HOME/ROOT" "$HOME" -maxdepth 1 -type d -name "pythia8*" 2>/dev/null | sort -V | tail -1)"
fi
if [ -n "${PYTHIA8:-}" ] && [ -f "${PYTHIA8}/include/Pythia8/Pythia.h" ]; then
    export PYTHIA8
    export PYTHIA8_INC="${PYTHIA8}/include"
    export PYTHIA8_LIB="${PYTHIA8}/lib"
    [ -d "${PYTHIA8}/share/Pythia8/xmldoc" ] && export PYTHIA8DATA="${PYTHIA8}/share/Pythia8/xmldoc"
else
    unset PYTHIA8
fi

# --- PDFs: GENIE ships its own LHAPDF sets ----------------------------------
export LHAPATH="${GENIE}/data/evgen/pdfs"
export LHAPDF_DATA_PATH="${GENIE}/data/evgen/pdfs${LHAPDF_DATA_PATH:+:${LHAPDF_DATA_PATH}}"

# --- TPythia6 ------------------------------------------------------------------
export LINUX_SYS_INCLUDES="-I${TPYTHIA6_PATH}/include/TPythia6"
export SYSLIBS="-L${TPYTHIA6_PATH}/lib"

# --- run-time paths ------------------------------------------------------------
export PATH="${GENIE_INSTALL}/bin:${PATH}"
_ld="${GENIE_INSTALL}/lib:${GENIE_EXT_INSTALL}/lib"
[ "${LHAPDF6_LIB}" != "${GENIE_EXT_INSTALL}/lib" ] && _ld="${_ld}:${LHAPDF6_LIB}"
[ -n "${PYTHIA8_LIB:-}" ] && _ld="${_ld}:${PYTHIA8_LIB}"
export LD_LIBRARY_PATH="${_ld}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
unset _ld
export ROOT_INCLUDE_PATH="${GENIE_INSTALL}/include/GENIE:${TPYTHIA6_PATH}/include/TPythia6${ROOT_INCLUDE_PATH:+:${ROOT_INCLUDE_PATH}}"

echo "GENIE env (Ubuntu): ROOT $(root-config --version) ($(root-config --prefix)), arch $(root-config --arch)"
echo "  GENIE         = ${GENIE}"
echo "  GENIE_INSTALL = ${GENIE_INSTALL}"
echo "  LHAPDF6       = ${LHAPDF6_LIB}"
echo "  PYTHIA8       = ${PYTHIA8:-<none>}"
