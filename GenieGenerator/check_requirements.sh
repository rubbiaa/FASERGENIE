#!/bin/bash
# -----------------------------------------------------------------------------
# check_requirements.sh -- GENIE (FASER fork): are all external pieces there?
#
#     ./check_requirements.sh              (site detected as in setup.sh / build.sh)
#     GENIE_SITE=ubuntu ./check_requirements.sh
#     WITH_PYTHIA8=1 WITH_APFEL=1 ./check_requirements.sh   (make those required)
#
# Checks, for the detected platform (mac, lcg, ubuntu):
#   1) platform prerequisites   things you must provide (apt packages, CVMFS view, Xcode, conda env)
#   2) environment              sources setup_<site>.sh in this process (your shell is not touched)
#   3) libraries and tools      compilers, ROOT (+Geom/MathMore/EG), libxml2, log4cpp, LHAPDF 6
#   4) built by build.sh        Pythia6, TPythia6, APFEL, GENIE itself
#   5) inputs for running       splines, flux files, geometry used by faser/run*.sh
#
# Status:  [ok]  [MISSING] (you must install it)  [TO BUILD] (./build.sh makes it)
#          [RUN] (needed only to run)  [ -- ] (optional, absent)  [WARN]
# Exit:    0 ready to run, 1 prerequisites missing, 2 run ./build.sh, 3 built but run inputs missing
# -----------------------------------------------------------------------------
shopt -s nullglob
_real="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
DIR="$( cd "$( dirname "${_real}" )" >/dev/null 2>&1 && pwd )"
WITH_APFEL=${WITH_APFEL:-0}
WITH_PYTHIA8=${WITH_PYTHIA8:-0}

n_miss=0; n_build=0; n_run=0
ok()      { printf '  [ok]        %-14s %s\n' "$1" "$2"; }
miss()    { printf '  [MISSING]   %-14s %s\n' "$1" "$2"; n_miss=$((n_miss+1)); }
tobuild() { printf '  [TO BUILD]  %-14s %s\n' "$1" "$2"; n_build=$((n_build+1)); }
runreq()  { printf '  [RUN]       %-14s %s\n' "$1" "$2"; n_run=$((n_run+1)); }
opt()     { printf '  [ -- ]      %-14s %s\n' "$1" "$2"; }
warn()    { printf '  [WARN]      %-14s %s\n' "$1" "$2"; }
section() { echo; echo "== $*"; }
find_lib() {   # dir name -> prints the first lib<name>.{so,dylib} found
    local f
    for f in "$1"/lib"$2".so "$1"/lib"$2".so.* "$1"/lib"$2".dylib "$1"/lib"$2".*.dylib; do
        [ -e "$f" ] && { echo "$f"; return 0; }
    done
    return 1
}
chk_lib() {    # label dir name [missing-handler] [hint]
    local f; if f=$(find_lib "$2" "$3"); then ok "$1" "$f"; else "${4:-miss}" "$1" "lib$3 not in ${2:-<unset>}${5:+ -- $5}"; fi
}
chk_file() {   # label file [missing-handler] [hint]
    if [ -n "$2" ] && [ -e "$2" ]; then ok "$1" "$2"; else "${3:-miss}" "$1" "${2:-<unset>}${4:+ -- $4}"; fi
}
chk_cmd() {    # label command [hint]
    local p; if p=$(command -v "$2" 2>/dev/null); then ok "$1" "$p"; else miss "$1" "'$2' not found${3:+ -- $3}"; fi
}

# ---- site ------------------------------------------------------------------
SITE="${GENIE_SITE:-}"
if [ -z "${SITE}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then SITE=mac
    else
        _id="$( . /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}" )"
        case "${_id}" in
            *ubuntu*|*debian*) SITE=ubuntu ;;
            *) [ -d /cvmfs/sft.cern.ch/lcg/views ] && SITE=lcg ;;
        esac
    fi
fi
case "${SITE}" in mac|lcg|ubuntu) ;; *)
    echo "check_requirements.sh: could not detect the site; set GENIE_SITE=mac|lcg|ubuntu"; exit 1 ;;
esac
echo "GENIE requirements check: site = ${SITE}  ($(uname -sm); WITH_PYTHIA8=${WITH_PYTHIA8} WITH_APFEL=${WITH_APFEL})"

# ---- 1) platform prerequisites ----------------------------------------------
section "1) platform prerequisites (${SITE})"
can_setup=1
case "${SITE}" in
mac)
    [ "$(uname -m)" = arm64 ] || warn "CPU" "$(uname -m): the scripts are written for Apple Silicon"
    if sdk=$(xcrun --show-sdk-path 2>/dev/null); then ok "Xcode CLT" "${sdk}"
    else miss "Xcode CLT" "run: xcode-select --install"; fi
    chk_cmd "curl" curl
    env_name=${GENIE_CONDA_ENV:-genie}; envp="${GENIE_CONDA_PREFIX:-}"
    if [ -z "${envp}" ]; then
        for p in "${MINIFORGE:-$HOME/miniforge3}/envs/${env_name}" \
                 "$HOME/opt/anaconda3/envs/${env_name}" "$HOME/anaconda3/envs/${env_name}"; do
            [ -d "${p}/conda-meta" ] && { envp="${p}"; break; }
        done
    fi
    if [ -z "${envp}" ]; then
        tobuild "conda env" "'${env_name}' not found: build.sh installs Miniforge (if needed) and creates it"
        can_setup=0
    else
        ok "conda env" "${envp}"
        cver() { local f; for f in "${envp}"/conda-meta/"$1"-[0-9]*.json; do f=${f##*/}; f=${f#"$1"-}; echo "${f%%-*}"; return; done; }
        for pkg in root lhapdf gsl libxml2 log4cpp cmake make clang_osx-arm64 clangxx_osx-arm64 gfortran_osx-arm64; do
            v=$(cver "${pkg}")
            if [ -n "$v" ]; then ok "  ${pkg}" "$v"; else miss "  ${pkg}" "mamba install -p ${envp} -c conda-forge ${pkg}"; fi
        done
        vc=$(cver clang); vh=$(cver libcxx-headers)
        if [ -n "$vc" ] && [ -n "$vh" ]; then
            if [ "${vc%%.*}" = "${vh%%.*}" ]; then ok "clang/libc++" "clang ${vc}, libcxx-headers ${vh}"
            else warn "clang/libc++" "clang ${vc} vs libcxx-headers ${vh}: mismatch breaks <charconv>; build.sh installs a matching clang"; fi
        fi
    fi
    ;;
lcg)
    . /etc/os-release 2>/dev/null
    case "${ID:-}" in rhel|almalinux|rocky|centos) [ "${VERSION_ID%%.*}" = 9 ] || warn "OS" "${PRETTY_NAME}: default LCG_PLATFORM is el9";; esac
    LCG_VERSION=${LCG_VERSION:-LCG_107}; LCG_PLATFORM=${LCG_PLATFORM:-x86_64-el9-gcc13-opt}
    view=/cvmfs/sft.cern.ch/lcg/views/${LCG_VERSION}/${LCG_PLATFORM}
    if [ ! -d /cvmfs/sft.cern.ch/lcg ]; then miss "CVMFS" "/cvmfs/sft.cern.ch not mounted"; can_setup=0
    elif [ ! -f "${view}/setup.sh" ]; then
        miss "LCG view" "${view} not found; available: $(ls /cvmfs/sft.cern.ch/lcg/views 2>/dev/null | grep -E '^LCG_1[0-9]{2}$' | sort -V | tail -4 | tr '\n' ' ')"
        can_setup=0
    else ok "LCG view" "${view}"; fi
    ;;
ubuntu)
    for pkg in build-essential gfortran cmake libxml2-dev libgsl-dev liblog4cpp5-dev curl; do
        if v=$(dpkg-query -W -f='${Version}' "${pkg}" 2>/dev/null) && [ -n "$v" ]; then ok "${pkg}" "$v"
        else miss "${pkg}" "sudo apt install ${pkg}"; fi
    done
    if grep -qsE 'throw *\(std::invalid_argument\)' /usr/local/include/log4cpp/Priority.hh; then
        warn "old log4cpp" "/usr/local/include/log4cpp is log4cpp 1.0 (not C++17); gcc searches it before /usr/include, so setup_ubuntu.sh uses a shim"
    fi
    ;;
esac

# ---- 2) environment ----------------------------------------------------------
section "2) environment (setup_${SITE}.sh)"
if [ "${can_setup}" = 1 ]; then
    if setup_out=$( . "${DIR}/setup_${SITE}.sh" 2>&1 ) && . "${DIR}/setup_${SITE}.sh" >/dev/null 2>&1; then
        ok "setup" "GENIE=${GENIE}"
    else
        miss "setup" "setup_${SITE}.sh failed:"; echo "${setup_out}" | sed 's/^/                 | /'
        can_setup=0
    fi
else
    opt "setup" "skipped until the items above are fixed"
fi

if [ "${can_setup}" = 1 ]; then
    if [ "${SITE}" = mac ]; then libext=dylib; else libext=so; fi

    # ---- 3) libraries and tools ------------------------------------------------
    section "3) compilers, ROOT and libraries"
    if [ "${SITE}" = mac ]; then
        chk_cmd "C++ compiler" "${GENIE_CXX:-clang++}"
        chk_cmd "Fortran" "${FC:-gfortran}"
    else
        chk_cmd "C++ compiler" g++
        chk_cmd "Fortran" gfortran
    fi
    chk_cmd "cmake" cmake
    chk_cmd "make" make
    if command -v root-config >/dev/null 2>&1; then
        rv=$(root-config --version); rlib=$(root-config --libdir)
        ok "ROOT" "${rv}  ($(root-config --prefix), $(root-config --cflags | grep -oE -- '-std=[^ ]+'))"
        for l in Core Geom MathMore EG Physics; do
            chk_lib "  lib${l}" "${rlib}" "${l}" miss "ROOT must be built with geom and mathmore"
        done
        rmaj=${rv%%.*}; rmin=${rv#*.}; rmin=${rmin%%[./]*}
        if [ "${rmaj}" -eq 6 ] && [ "${rmin}" -lt 26 ] 2>/dev/null; then
            warn "ROOT version" "${rv}: tested with 6.32 and 6.40"
        fi
    else
        miss "ROOT" "root-config not on PATH after setup_${SITE}.sh"
    fi
    chk_file "libxml2 inc" "${LIBXML2_INC:-}/libxml/parser.h"
    chk_lib  "libxml2 lib" "${LIBXML2_LIB:-}" xml2
    chk_file "log4cpp inc" "${LOG4CPP_INC:-}/log4cpp/Category.hh"
    if [ "${GENIE_OLD_LOG4CPP_USRLOCAL:-0}" = 1 ]; then
        case "${LOG4CPP_INC:-}" in
            /usr/include|/usr/local/include|"") miss "log4cpp shim" "old log4cpp in /usr/local/include would be used: move /usr/local/include/log4cpp away";;
            *) ok "log4cpp shim" "apt headers via ${LOG4CPP_INC} (ahead of the old /usr/local/include/log4cpp)";;
        esac
    fi
    chk_lib  "log4cpp lib" "${LOG4CPP_LIB:-}" log4cpp
    if ls /usr/local/lib/liblog4cpp.so* >/dev/null 2>&1; then
        if [ -n "${GENIE_LOG4CPP_SHIM_LIB:-}" ]; then
            ok "log4cpp shim" "apt library via ${GENIE_LOG4CPP_SHIM_LIB} (ahead of /usr/local/lib/liblog4cpp)"
        else
            warn "log4cpp lib" "/usr/local/lib/liblog4cpp* may be loaded instead of the apt library at run time"
        fi
        if [ -x "${GENIE_INSTALL}/bin/gevgen_faser" ]; then
            l4=$(ldd "${GENIE_INSTALL}/bin/gevgen_faser" 2>/dev/null | awk '/liblog4cpp/{print $3; exit}')
            case "$l4" in /usr/local/*) miss "log4cpp run" "gevgen_faser loads ${l4}";; "") ;; *) ok "log4cpp run" "gevgen_faser loads ${l4}";; esac
        fi
    fi
    lh_handler=miss; [ "${SITE}" = ubuntu ] && lh_handler=tobuild     # built from source if absent
    chk_file "LHAPDF6 inc" "${LHAPDF6_INC:-}/LHAPDF/LHAPDF.h" "${lh_handler}"
    chk_lib  "LHAPDF6 lib" "${LHAPDF6_LIB:-}" LHAPDF "${lh_handler}"
    pdfs=( "${GENIE}"/data/evgen/pdfs/* )
    if [ ${#pdfs[@]} -gt 0 ]; then ok "PDF sets" "${GENIE}/data/evgen/pdfs (${#pdfs[@]} entries)"
    else miss "PDF sets" "${GENIE}/data/evgen/pdfs is empty"; fi

    # ---- 4) built by build.sh ----------------------------------------------------
    section "4) built by build.sh"
    if [ "${SITE}" = lcg ]; then
        chk_lib "Pythia6" "${PYTHIA6_LIB:-}" pythia6 miss "not in this LCG view, try another LCG_VERSION"
    else
        chk_lib "Pythia6" "${PYTHIA6_LIB:-}" pythia6 tobuild
    fi
    [ "${SITE}" = mac ] || chk_file "libPythia6" "${GENIE_EXT_INSTALL}/lib/libPythia6.${libext}" tobuild "alias GENIE links against"
    chk_lib  "TPythia6" "${TPYTHIA6_PATH}/lib" EGPythia6 tobuild
    chk_file "  rootmap" "${TPYTHIA6_PATH}/lib/libEGPythia6.rootmap" tobuild
    chk_file "  headers" "${TPYTHIA6_PATH}/include/TPythia6/TPythia6.h" tobuild
    if [ "${WITH_APFEL}" = 1 ]; then
        if [ "${SITE}" = lcg ]; then chk_lib "APFEL" "${APFEL_LIB:-}" APFEL miss "not in this LCG view"
        else chk_lib "APFEL" "${APFEL_LIB:-}" APFEL tobuild "WITH_APFEL=1 ./build.sh"; fi
    else
        f=$(find_lib "${APFEL_LIB:-/nonexistent}" APFEL) && ok "APFEL" "$f (optional)" || opt "APFEL" "not used (WITH_APFEL=1 for HEDIS)"
    fi
    p8h="${PYTHIA8_INC:-}/Pythia8/Pythia.h"
    if [ "${WITH_PYTHIA8}" = 1 ]; then
        chk_file "Pythia8 inc" "${PYTHIA8_INC:+${p8h}}" miss "set PYTHIA8=/path/to/pythia8xxx"
        chk_lib  "Pythia8 lib" "${PYTHIA8_LIB:-}" pythia8
    elif [ -n "${PYTHIA8_INC:-}" ] && [ -f "${p8h}" ]; then ok "Pythia8" "${PYTHIA8_INC%/include} (optional, WITH_PYTHIA8=1 to use)"
    else opt "Pythia8" "not found (optional)"; fi
    if grep -q kG4Units "${GENIE}/src/Tools/Geometry/FaserROOTGeomAnalyzer.cxx" 2>/dev/null; then
        ok "TGeo units" "FaserROOTGeomAnalyzer forces mm (needed with ROOT >= 6.26)"
    else
        warn "TGeo units" "FaserROOTGeomAnalyzer has no kG4Units fix: geometry 10x too small with ROOT >= 6.26"
    fi
    chk_file "GENIE config" "${GENIE}/src/make/Make.config" tobuild
    for b in gevgen_faser gmkspl_faser gevdump; do
        chk_file "  ${b}" "${GENIE_INSTALL}/bin/${b}" tobuild
    done
    glibs=( "${GENIE_INSTALL}"/lib/libGFw*."${libext}" )
    if [ ${#glibs[@]} -gt 0 ]; then ok "  GENIE libs" "${GENIE_INSTALL}/lib ($(ls "${GENIE_INSTALL}"/lib/libG*."${libext}" | wc -l | tr -d ' ') libraries)"
    else tobuild "  GENIE libs" "${GENIE_INSTALL}/lib"; fi

    # ---- 5) inputs for running ---------------------------------------------------
    section "5) inputs for running (faser/run*.sh)"
    xs="${GENIE_HOME}/faser_xsec/faserSplines.7TeV.xml"
    if [ -e "${xs}" ]; then
        case "$(readlink -f "${xs}")" in
            *GENIE3.04*) warn "splines" "${xs} -> $(readlink -f "${xs}") (3.04 splines: testing only, regenerate with faser/Splines)";;
            *) ok "splines" "${xs}";;
        esac
    else runreq "splines" "${xs} -- make with faser/Splines (days) or copy/link them"; fi
    chk_file "geometry" "${GENIE}/faser/FASERCAL_V10.gdml" runreq
    for fl in Aki_2024/events_light_4x4.root Aki_2024/events_charm_4x4.root Kling_2021/Kling_2021.root; do
        chk_file "flux" "${GENIE}/faser/Fluxes/${fl}" runreq
    done
    for fl in Kling_2023/DPMJET.root Kling_2023/SIBYLL.root; do   # git-ignored, large
        chk_file "flux" "${GENIE}/faser/Fluxes/${fl}" opt "regenerate with Kling_2023/getRawFluxes.sh + convertAllFluxes.sh"
    done
fi

# ---- summary ---------------------------------------------------------------------
echo
if   [ ${n_miss}  -gt 0 ]; then echo "RESULT: ${n_miss} prerequisite(s) MISSING -- install them, then ./build.sh"; rc=1
elif [ ${n_build} -gt 0 ]; then echo "RESULT: prerequisites OK; ${n_build} item(s) still TO BUILD -- run ./build.sh"; rc=2
elif [ ${n_run}   -gt 0 ]; then echo "RESULT: GENIE built; ${n_run} input(s) for running missing (see [RUN])"; rc=3
else echo "RESULT: all OK -- source setup.sh and run"; rc=0; fi
exit ${rc}
