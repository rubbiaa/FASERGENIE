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
├── README.md  GENIE_3.04_vs_3.06.md  run_genie.py
├── setup.sh  build.sh  setup_<site>.sh  build_genie_<site>.sh   <- shortcuts (site = mac, lcg, ubuntu)
├── GenieGenerator/           <- GENIE source tree (GENIE)
│   ├── setup*.sh  build*.sh
│   └── faser/                <- FASER scripts: run*.sh, Splines/, Ntuple/, build/external/
├── data/
│   ├── GDML/                 <- current geometry: FASERCAL_V10.gdml
│   ├── obsolete/             <- older geometries (FASERCAL V6-V9, FaserNu2-4, geometry_v4-v6, ...)
│   └── fluxes/               <- Aki_2024/, Kling_2021/, Kling_2023/ and getFluxNtp.sh
├── install/  build/          <- created by the build script (git-ignored)
├── external/downloads/       <- cached source tarballs
├── external/install/         <- Pythia6, TPythia6 (and APFEL): kept apart from install/
├── faser_xsec/               <- cross-section splines (git-ignored; make or copy them here)
└── output/                   <- $GENIE_OUTPUT: .ghep.root, .gfaser.root, status files, run logs (git-ignored)
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

- **ROOT**: `ROOT_THISROOT=/path/bin/thisroot.sh` if set; else a self-built ROOT already on the PATH; otherwise
  the newest `~/ROOT/root_install*/bin/thisroot.sh`,
  then `~/root`, `/opt/root`, `/usr/local`. A snap ROOT (`/snap/...`) is used only if nothing else is found. It must have been built with `geom` and `mathmore`
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

## Running GENIE: run_genie.py

`run_genie.py` (top directory, needs `source setup.sh`) builds and runs the `gevgen_faser`
commands for you, in the style of the FASER repository's `run_convertgenie.py`. By default it
generates **two samples side by side**, the Aki 2024 **light** and **charm** fluxes, each with
its own files (`fasercal.Aki2024.v10.light.*`, `fasercal.Aki2024.v10.charm.*`):

```bash
python3 run_genie.py                           # light + charm, 1000 fb^-1 each, 1 job each
python3 run_genie.py --jobs 8 --merge --export # 8+8 parallel jobs -> one light, one charm file
python3 run_genie.py --flux light              # one sample only
python3 run_genie.py --dry-run                 # show the plan and the commands only
```

Inputs are found automatically (the single `.gdml` in `data/GDML`, `data/fluxes/Aki_2024/
events_<flux>_4x4.root`, `faser_xsec/faserSplines.7TeV.xml`; override with `--geometry-file`,
`--flux-file`, `--splines`). Each sample gets the full `--lumi`, split evenly over `--jobs`
(run numbers `--run`, `--run+1`, ...; seed = 2999833 + run for light, 3999833 + run for charm,
or `--seed`); all jobs share one queue of at most `--max-parallel`. Output goes to `output/`:
by default only the `.gfaser.root` per job (`gevgen_faser --gfaser --no-ghep`); `--ghep` also
keeps the GENIE `.ghep.root`, `--ghep-only` writes only that; `--cc-only`, a log and a
`<prefix>.<run>.status` file per job, and per sample a record of the exact commands
(`<prefix>.r<runs>.run_genie.sh`) and a summary (`<prefix>.r<runs>.run_genie_summary.log`).
`--merge` hadds each sample separately into `<prefix>.all.gfaser.root` (one light, one charm
file); `--export` copies those, with their records and summaries, to `$FASERDATA/GENIE` for the
FASER simulation. `python3 run_genie.py -h` lists all options.

## Event output: GHEP and gFaser

`gevgen_faser` writes the GENIE GHEP file `[prefix].[run].ghep.root` (unless `--no-ghep`).
With `--gfaser` it also writes the flat FASER ntuple `[prefix].[run].gfaser.root`
(tree `gFaser`) during generation, so `faser/Ntuple/convertGHEP.C` is no longer needed:

```bash
gevgen_faser -l 1000.0 -r 0 -g $GENIE_HOME/data/GDML/FASERCAL_V10.gdml \
   -f $GENIE_HOME/data/fluxes/Aki_2024/events_light_4x4.root --seed 2999833 \
   --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml \
   -o fasercal.Aki2024.v10.light --gfaser          # or --gfaser-cc-only; add --no-ghep for gFaser only
```

All output files (GHEP, gFaser, `[prefix].[run].status`) go to `$GENIE_OUTPUT`, which
`setup.sh` sets to `GENIE3.06/output/`; use `--output-dir dir` for another place, or give `-o` a
prefix with a directory. The `faser/run*.sh` scripts also run (and write their logs) there.

The branches are those of `convertGHEP.C` (`vx vy vz n name pdgc status firstMother
lastMother firstDaughter lastDaughter px py pz E m M`). One difference: in `convertGHEP.C`
the `M` branch is filled from the `m` vector (a bug), so there `M` = PDG mass; with
`--gfaser`, `M` is the actual (off-shell) mass. `--gfaser-cc-only` applies the same CC
selection as `convertGHEP.C(..., true)` to the gFaser file only. When the run is
normalized to POT, the gFaser tree carries the same weight as the GHEP tree.

## Flux files

Fluxes live in `data/fluxes/` (geometries in `data/GDML/`, old ones in `data/obsolete/`).
The large Kling 2023 flux ntuples (`data/fluxes/Kling_2023/*.root`, up to 575 MB) are not in
git: download them with `data/fluxes/getFluxNtp.sh`, regenerate them with
`data/fluxes/Kling_2023/getRawFluxes.sh` and `convertAllFluxes.sh`, or copy them from an
existing installation.

## Splines

Splines are GENIE-version specific. The recipe is in `GenieGenerator/faser/Splines/`
(`calcSplinesN.sh` → `mergeSplinesN.sh` → `calc*SplinesA.sh` → `mergeSplinesA.sh`);
the run scripts expect `$GENIE_HOME/faser_xsec/faserSplines.7TeV.xml`.
