# GENIE 3.06.02 — FASER fork

This is the official [GENIE](http://www.genie-mc.org) neutrino event generator, release
**R-3_06_02**, with the FASER additions ported from `faser-R-3_04_00`
(gitlab.cern.ch/faser/offline/geniegenerator): `gevgen_faser`, `gmkspl_faser`,
`FaserGMCJDriver`, `FaserROOTGeomAnalyzer`, the 7 TeV validity range, the `F23_00a` tune
and the `faser/` directory (geometries, fluxes, run and spline scripts).

- What changed with respect to the FASER 3.04 fork: [GENIE_3.04_vs_3.06.md](GENIE_3.04_vs_3.06.md)
- The original GENIE README: [GenieGenerator/README.md](GenieGenerator/README.md)

## Building without the ATLAS container

These scripts build this GENIE tree plus its external pieces (Pythia6, TPythia6,
optionally APFEL and Pythia8) natively, either on macOS/Apple Silicon or on any
EL9 machine with CVMFS (e.g. lxplus), or on a plain Ubuntu/Debian machine. They replace the old
`ATLAS_container.sh` / `asetup` / `setupGenerator.sh` / `buildGenerator.sh` chain.

The scripts live in `GenieGenerator/` (with shortcuts in the top directory);
their helpers are in `GenieGenerator/faser/build/external/`.

| file | purpose |
|---|---|
| `setup.sh` | **one entry point**: detects the site (macOS / Ubuntu / EL9+CVMFS) and sources the matching `setup_*.sh`, then prints a sanity check; override with `GENIE_SITE=mac\|lcg\|ubuntu` |
| `build.sh` | same detection, runs `check_requirements.sh` and then the matching `build_genie_*.sh` |
| `check_requirements.sh` | lists, for this platform, every external piece: what you must install (`[MISSING]`), what `build.sh` will build (`[TO BUILD]`), and the splines/fluxes/geometry needed to run (`[RUN]`) |
| `build_genie_mac.sh` | one-time build on macOS (conda-forge env in `~/miniforge3/envs/genie`) |
| `setup_mac.sh` | environment for every new terminal on macOS (zsh or bash) |
| `build_genie_lcg.sh` | one-time build on EL9 from a plain LCG view (`LCG_107` by default) |
| `setup_lcg.sh` | environment for every new shell on EL9 |
| `build_genie_ubuntu.sh` | one-time build on Ubuntu/Debian with your own ROOT and apt packages |
| `setup_ubuntu.sh` | environment for every new shell on Ubuntu/Debian |
| `GenieGenerator/faser/build/external/patch_genie_make.sh` | idempotent fixes to `src/make/Make.include` (Apple Silicon flags, Pythia6 link line) |
| `GenieGenerator/faser/build/external/pythia6/CMakeLists.txt` | builds Pythia 6.4.28 + ROOT interface as one shared library |
| `GenieGenerator/faser/TPythia6_standalone/` | plain-CMake build of ROOT's old TPythia6 classes (`libEGPythia6`) |

## Layout

The repository is the work directory itself. Builds, installs, downloads, splines and
event output are created next to `GenieGenerator/` and are ignored by git (`.gitignore`):

```
GENIE3.06/                    <- this repository = work directory (GENIE_HOME)
├── README.md  GENIE_3.04_vs_3.06.md
├── setup.sh  build.sh  setup_<site>.sh  build_genie_<site>.sh   <- shortcuts (site = mac, lcg, ubuntu)
├── GenieGenerator/           <- GENIE source tree (GENIE)
│   ├── setup*.sh  build*.sh
│   └── faser/build/external/ <- helpers used by the build scripts
├── install/  build/          <- created by the build script (git-ignored)
├── external/downloads/       <- cached source tarballs
├── external/install/         <- Pythia6, TPythia6 (and APFEL): kept apart from install/
├── faser_xsec/               <- cross-section splines (git-ignored; make or copy them here)
└── run/                      <- event output used by faser/run*.sh (git-ignored)
```

## Quick start (macOS)

```bash
git clone https://github.com/rubbiaa/GENIE.git GENIE3.06
cd GENIE3.06
./check_requirements.sh                              # optional: what is there, what is missing
./build.sh                                           # ~20 min the first time
source setup.sh                                      # every new terminal
```

`build.sh` / `setup.sh` pick the right per-site script (`*_mac.sh`, `*_lcg.sh`, `*_ubuntu.sh`);
you can also call those directly.

Options (environment variables for the build scripts):
`WITH_PYTHIA8=1` (Pythia8 hadronization), `WITH_APFEL=1` (needed only for the HEDIS model),
`NJ=<n>` (parallel jobs); for LCG also `LCG_VERSION`, `LCG_PLATFORM`.

## Ubuntu / Debian notes

No conda and no CVMFS: it uses your own ROOT and the distribution packages.

```bash
sudo apt install build-essential gfortran cmake libxml2-dev libgsl-dev liblog4cpp5-dev curl
./build.sh            # = ./build_genie_ubuntu.sh; stops with the apt line if a package is missing
source setup.sh
```

- **ROOT**: taken from the PATH if `root-config` is already there; otherwise
  `ROOT_THISROOT=/path/bin/thisroot.sh`, otherwise the newest `~/ROOT/root_install*/bin/thisroot.sh`,
  then `~/root`, `/opt/root`, `/usr/local`. It must have been built with `geom` and `mathmore`
  (the build script checks for `libGeom`, `libMathMore`, `libEG`). Any ROOT 6.26+ works; TPythia6 is
  built separately, so ROOT ≥ 6.32 is fine.
- **LHAPDF 6**: a system `lhapdf-config` is used if present; otherwise LHAPDF 6.5.4 is built into
  `external/install` (no Python bindings).
- **Pythia8** (optional): `PYTHIA8=/path/to/pythia8xxx`, or found automatically as `~/ROOT/pythia8*`
  or `~/pythia8*`; build with `WITH_PYTHIA8=1 ./build.sh`.
- Pythia6, TPythia6 (and APFEL with `WITH_APFEL=1`) are built into `external/install` as on macOS.

## macOS notes

The macOS build is native (Apple Silicon) and uses conda-forge's ROOT, LHAPDF, GSL,
libxml2, log4cpp and compilers. The scripts handle a few pitfalls automatically:

- **Matching clang:** clang is matched to the libc++ headers that ROOT pulls in; the
  `compilers` metapackage would give an older clang.
- **Two compiler workarounds** (also passed to `rootcling`):
  - `-D_LIBCPP_DISABLE_AVAILABILITY`, which unblocks newer C++ library features;
  - `-std=gnu++20`, needed for `NAN`/`INFINITY` with the macOS 27 SDK.
- **Separate prefix for the externals:** Pythia6, TPythia6 and APFEL install into
  `external/install/`, because GENIE's `make distclean` empties `install/`.

Run the event-generation scripts with `source`, not `./`: macOS strips `DYLD_*`
variables from `/bin/bash` scripts (the libraries have absolute install names, so
this is only a precaution).

## Flux files

The large Kling 2023 flux ntuples (`GenieGenerator/faser/Fluxes/Kling_2023/*.root`, up to 575 MB)
are not in git; regenerate them with `GenieGenerator/faser/Fluxes/Kling_2023/getRawFluxes.sh` and
`convertAllFluxes.sh`, or copy them from an existing installation.

## Splines

Splines are GENIE-version specific. The recipe is in `GenieGenerator/faser/Splines/`
(`calcSplinesN.sh` → `mergeSplinesN.sh` → `calc*SplinesA.sh` → `mergeSplinesA.sh`);
the run scripts expect `$GENIE_HOME/faser_xsec/faserSplines.7TeV.xml`.
