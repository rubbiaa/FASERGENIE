#!/bin/bash
# -----------------------------------------------------------------------------
# build.sh -- GENIE (FASER fork): one-time build on any supported machine
#
#     ./build.sh                 (same options as the per-site scripts:
#                                 WITH_PYTHIA8=1, WITH_APFEL=1, NJ=<n>, ...)
#
# Runs build_genie_mac.sh, build_genie_lcg.sh or build_genie_ubuntu.sh, with the
# same site detection as setup.sh; override with GENIE_SITE=mac|lcg|ubuntu.
# Runs check_requirements.sh first and stops if a prerequisite is missing (SKIP_CHECK=1 to skip).
# -----------------------------------------------------------------------------
set -eu
_real="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
DIR="$( cd "$( dirname "${_real}" )" >/dev/null 2>&1 && pwd )"

SITE="${GENIE_SITE:-}"
if [ -z "${SITE}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
        SITE=mac
    else
        _id="$( . /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}" )"
        case "${_id}" in
            *ubuntu*|*debian*) SITE=ubuntu ;;
            *) [ -d /cvmfs/sft.cern.ch/lcg/views ] && SITE=lcg || true ;;
        esac
    fi
fi
case "${SITE}" in
    mac|lcg|ubuntu)
        echo "GENIE build: site = ${SITE}"
        if [ "${SKIP_CHECK:-0}" != 1 ]; then          # stop early if a prerequisite is missing
            rc=0; GENIE_SITE="${SITE}" bash "${DIR}/check_requirements.sh" || rc=$?
            [ "${rc}" = 1 ] && { echo "GENIE build: fix the [MISSING] items above (or SKIP_CHECK=1 ./build.sh)"; exit 1; }
        fi
        exec bash "${DIR}/build_genie_${SITE}.sh" "$@" ;;
    *) echo "GENIE build: could not detect the site; set GENIE_SITE=mac|lcg|ubuntu"; exit 1 ;;
esac
