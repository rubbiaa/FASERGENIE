# Building GENIE (FASER fork) without the ATLAS container

These scripts build this GENIE tree plus its external pieces (Pythia6, TPythia6,
optionally APFEL and Pythia8) natively, either on macOS/Apple Silicon or on any
EL9 machine with CVMFS (e.g. lxplus). They replace the old
`ATLAS_container.sh` / `asetup` / `setupGenerator.sh` / `buildGenerator.sh` chain.

| file | purpose |
|---|---|
| `build_genie_mac.sh` | one-time build on macOS (conda-forge env in `~/miniforge3/envs/genie`) |
| `setup_mac.sh` | environment for every new terminal on macOS (zsh or bash) |
| `build_genie_lcg.sh` | one-time build on EL9 from a plain LCG view (`LCG_107` by default) |
| `setup_lcg.sh` | environment for every new shell on EL9 |
| `external/patch_genie_make.sh` | idempotent fixes to `src/make/Make.include` (Apple Silicon flags, Pythia6 link line) |
| `external/pythia6/CMakeLists.txt` | builds Pythia 6.4.28 + ROOT interface as one shared library |
| `../TPythia6_standalone/` | plain-CMake build of ROOT's old TPythia6 classes (`libEGPythia6`) |

## Layout

Clone the repository as `GenieGenerator` inside a dedicated work directory.
Builds, installs, downloads, splines and event output go to that work directory,
never into the repository:

```
GENIE3.06/                    <- work directory (GENIE_HOME)
├── GenieGenerator/           <- this repository (GENIE)
│   └── faser/build/          <- these scripts
├── install/  build/          <- created by the build script
├── external/downloads/       <- cached source tarballs
├── faser_xsec/               <- cross-section splines (make or copy them here)
└── run/                      <- event output used by faser/run*.sh
```

## Quick start (macOS)

```bash
mkdir GENIE3.06 && cd GENIE3.06
git clone -b faser-R-3_06_02 https://github.com/rubbiaa/GENIE.git GenieGenerator
ln -s GenieGenerator/faser/build/setup_mac.sh .      # optional convenience link
GenieGenerator/faser/build/build_genie_mac.sh        # ~20 min the first time
source setup_mac.sh                                  # every new terminal
```

On lxplus use `build_genie_lcg.sh` / `setup_lcg.sh` instead.

Options (environment variables for the build scripts):
`WITH_PYTHIA8=1` (Pythia8 hadronization), `WITH_APFEL=1` (needed only for the HEDIS model),
`NJ=<n>` (parallel jobs); for LCG also `LCG_VERSION`, `LCG_PLATFORM`.

## Flux files

The large Kling 2023 flux ntuples (`faser/Fluxes/Kling_2023/*.root`, up to 575 MB)
are not in git; regenerate them with `faser/Fluxes/Kling_2023/getRawFluxes.sh` and
`convertAllFluxes.sh`, or copy them from an existing installation.

## Splines

Splines are GENIE-version specific. The recipe is in `faser/Splines/`
(`calcSplinesN.sh` → `mergeSplinesN.sh` → `calc*SplinesA.sh` → `mergeSplinesA.sh`);
the run scripts expect `$GENIE_HOME/faser_xsec/faserSplines.7TeV.xml`.
