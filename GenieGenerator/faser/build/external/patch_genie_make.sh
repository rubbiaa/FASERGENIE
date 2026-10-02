#!/bin/bash
# -----------------------------------------------------------------------------
# patch_genie_make.sh -- small, idempotent fixes to GENIE 3.04.00 src/make/Make.include
#   1) (3.04) Pythia6 link line used undefined variables (PYTHIA_DIR/PYTHIA_O/PYTHIA_LIBRARIES
#      vs PYTHIA6_*), so -lpythia6 was never actually on the link line.
#   2) Apple Silicon: root-config --arch is "macosxarm64".  GENIE 3.04.00 does not
#      know it at all; GENIE 3.06 lumps it with macosx64, whose flags are from the
#      Xcode-10 era (plain clang++, -bind_at_load, sometimes -stdlib=libstdc++) and
#      do not work with conda's compilers/ROOT.  Both get a dedicated block that
#      uses conda's clang (GENIE_CXX) and LDFLAGS (rpath to the conda env).
# Works on 3.04 (FASER fork) and 3.06; safe to run repeatedly.
# The original file is kept as Make.include.orig.
# Usage: patch_genie_make.sh <GENIE source dir>
# -----------------------------------------------------------------------------
set -euo pipefail
MK="${1:?usage: $0 <GENIE dir>}/src/make/Make.include"
[ -f "${MK}.orig" ] || cp -p "${MK}" "${MK}.orig"

# --- 1) Pythia6 variable names ----------------------------------------------
if grep -q '^PYTHIA_LIBRARIES' "${MK}"; then
  sed -i.bak \
    -e 's/^PYTHIA_LIBRARIES  = -L\$(PYTHIA_DIR) -lpythia6 \$(PYTHIA_O)/PYTHIA6_LIBRARIES = -L$(PYTHIA6_DIR) -lpythia6 $(PYTHIA6_O)/' \
    -e 's/^PYTHIA_LIBRARIES  = -L\$(PYTHIA_DIR) -lpythia6 *$/PYTHIA6_LIBRARIES = -L$(PYTHIA6_DIR) -lpythia6/' \
    "${MK}" && rm -f "${MK}.bak"
  echo "patched: Pythia6 link variables"
fi

# --- 1b) GENIE >= 3.06: libraries link $(ROOT_LIBRARIES), which contains -lEGPythia6,
#         without $(SYSLIBS); add the TPythia6 library directory to that flag.
if grep -q '^PY6ROOT_LIBRARY = -lEGPythia6' "${MK}"; then
  sed -i.bak 's/^PY6ROOT_LIBRARY = -lEGPythia6/PY6ROOT_LIBRARY = $(SYSLIBS) -lEGPythia6/' "${MK}" && rm -f "${MK}.bak"
  echo "patched: -lEGPythia6 gets the TPythia6 library path"
fi

# --- 2) macosxarm64 architecture block ---------------------------------------
# GENIE 3.06: take macosxarm64 out of the generic macosx64 block
if grep -q 'filter $(strip $(ARCH)),macosx64 macosxarm64' "${MK}"; then
  sed -i.bak 's/^ifneq (,$(filter $(strip $(ARCH)),macosx64 macosxarm64))/ifeq ($(strip $(ARCH)),macosx64)/' "${MK}" \
    && rm -f "${MK}.bak"
  echo "patched: macosxarm64 removed from generic macosx64 block"
fi

if ! grep -q 'added by patch_genie_make.sh' "${MK}"; then
  python3 - "${MK}" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
block = r'''
# MAC OS X / Apple Silicon (arm64) with clang   [added by patch_genie_make.sh]
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GENIE_CXX / GENIE_CC / GENIE_LDFLAGS come from setup_mac.sh (conda compilers)
ifeq ($(strip $(ARCH)),macosxarm64)
ARCH_OK       = YES
IS_MACOSX     = YES
ifdef GENIE_CXX
  CXX := $(GENIE_CXX)
  CC  := $(GENIE_CC)
  LD  := $(GENIE_CXX)
endif
CXXFLAGS      = -pipe -W -Wall -Wshadow -Woverloaded-virtual \
                -fsigned-char -fno-common -Wno-strict-aliasing \
                $(subst -std=c++,-std=gnu++,$(ROOT_FLAGS)) \
                $(GOPT_WITH_CXX_DEBUG_FLAG) \
                $(GOPT_WITH_CXX_OPTIMIZ_FLAG) \
                $(GOPT_WITH_CXX_USERDEF_FLAGS)
LDFLAGS       = $(GENIE_LDFLAGS)
# absolute install names -> executables find the installed dylibs without DYLD_*
SOFLAGS       = -dynamiclib -undefined dynamic_lookup $(GENIE_LDFLAGS) \
                -Wl,-install_name,$(GENIE_LIB_INSTALLATION_PATH)/$(@F)
DllSuf       := dylib
DllLinkSuf   := so
StaticLibSuf := a
ObjSuf       := o
SrcSuf       := cxx
FORT         := gfortran
FORTOPTS     := $(FFLAGS) -g -c -O $(F77INCS) -fno-second-underscore
RANLIB       := ranlib
SOCMD         = $(LD)
OutPutOpt     = -o
SOMINF        =
EXTRALIBS     =
endif
'''
anchor = "#-------------------------------------------------------------------\n# SUMMING-UP"
assert anchor in s, "anchor not found"
s = s.replace(anchor, block + "\n" + anchor, 1)
open(p, "w").write(s)
PYEOF
  echo "patched: macosxarm64 support"
fi

# --- 3) macosxarm64 block: GNU C++ dialect --------------------------------------
# With strict -std=c++NN, clang 20's <float.h> does not define NAN/INFINITY, and the
# macOS 27 SDK <math.h> relies on <float.h> for them ("undeclared identifier NAN"
# in <complex>).  Use -std=gnu++NN (same standard as ROOT, GNU extensions on).
python3 - "${MK}" <<'PYEOF'
import sys
p = sys.argv[1]; s = open(p).read()
i = s.find('[added by patch_genie_make.sh]')
if i >= 0:
    j = s.find('EXTRALIBS', i)
    blk = s[i:j]
    new = blk.replace('                $(ROOT_FLAGS) \\', '                $(subst -std=c++,-std=gnu++,$(ROOT_FLAGS)) \\')
    if new != blk:
        open(p, 'w').write(s[:i] + new + s[j:])
        print("patched: macosxarm64 block uses -std=gnu++")
PYEOF
