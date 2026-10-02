# -----------------------------------------------------------------------------
# setup.sh -- GENIE (FASER fork): one entry point for every machine
#
#     source setup.sh            (bash or zsh)
#
# Picks the site from the machine and sources the matching setup script:
#     macOS                      -> setup_mac.sh     (conda env ~/miniforge3/envs/genie)
#     EL9 with /cvmfs/sft.cern.ch -> setup_lcg.sh     (lxplus, LCG view)
#     Ubuntu / Debian            -> setup_ubuntu.sh  (own ROOT + apt packages)
# Override with GENIE_SITE=mac|lcg|ubuntu  (e.g. an Ubuntu box that also mounts CVMFS
# but where you want your own ROOT: GENIE_SITE=ubuntu source setup.sh).
# Then prints a short sanity check of what was found.
# -----------------------------------------------------------------------------

if [ -n "${BASH_VERSION:-}" ]; then
    _gs_here="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    eval '_gs_here="${(%):-%x}"'
fi
_gs_real="$(readlink -f "${_gs_here}" 2>/dev/null || echo "${_gs_here}")"
_gs_dir="$( cd "$( dirname "${_gs_real}" )" >/dev/null 2>&1 && pwd )"

_gs_site="${GENIE_SITE:-}"
if [ -z "${_gs_site}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
        _gs_site=mac
    else
        _gs_id="$( . /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}" )"
        case "${_gs_id}" in
            *ubuntu*|*debian*) _gs_site=ubuntu ;;
            *) [ -d /cvmfs/sft.cern.ch/lcg/views ] && _gs_site=lcg ;;
        esac
        unset _gs_id
    fi
fi

case "${_gs_site}" in
    mac|lcg|ubuntu)
        echo "GENIE setup: site = ${_gs_site}"
        . "${_gs_dir}/setup_${_gs_site}.sh" || { unset _gs_here _gs_real _gs_dir _gs_site; return 1 2>/dev/null || exit 1; }
        ;;
    *)
        echo "GENIE setup: could not detect the site (not macOS, Ubuntu/Debian, or EL9 with CVMFS)."
        echo "  Set GENIE_SITE=mac|lcg|ubuntu and source this again, or source setup_<site>.sh directly."
        unset _gs_here _gs_real _gs_dir _gs_site
        return 1 2>/dev/null || exit 1
        ;;
esac

# --- sanity check ------------------------------------------------------------
_gs_ok=1
_gs_check() {   # label value required|optional
    if [ -z "$2" ]; then
        if [ "$3" = required ]; then echo "  [MISSING]   $1 not set"; _gs_ok=0
        else echo "  [ -- ]      $1 not set (optional)"; fi
    elif [ ! -e "$2" ]; then
        echo "  [NOT FOUND] $1 = $2"; [ "$3" = required ] && _gs_ok=0
    else
        echo "  [ok]        $1 = $2"
    fi
}
echo "GENIE environment check:"
_gs_check "GENIE        " "${GENIE:-}"                       required
_gs_check "gevgen_faser " "${GENIE_INSTALL:-}/bin/gevgen_faser" optional
_gs_check "libEGPythia6 " "$(find "${TPYTHIA6_PATH:-/nonexistent}/lib" -maxdepth 1 -name "libEGPythia6.*" 2>/dev/null | head -1)" optional
_gs_check "LHAPDF6_LIB  " "${LHAPDF6_LIB:-}"                 optional
_gs_check "PYTHIA8      " "${PYTHIA8:-}"                     optional
_gs_check "splines      " "${GENIE_HOME:-}/faser_xsec"       optional
if [ "${_gs_ok}" = 1 ]; then
    [ -x "${GENIE_INSTALL:-}/bin/gevgen_faser" ] && echo "GENIE environment OK." \
        || echo "GENIE environment set, but GENIE is not built yet: run ./build.sh"
else
    echo "GENIE environment INCOMPLETE - see [MISSING] lines above."
fi
unset -f _gs_check
unset _gs_here _gs_real _gs_dir _gs_site _gs_ok
