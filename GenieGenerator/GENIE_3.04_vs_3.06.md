# GENIE for FASER: 3.04 → 3.06 differences

*Comparison of `faser-R-3_04_00` (gitlab.cern.ch/faser/offline/geniegenerator, last commit 2023-10-07)
with `main` of github.com/rubbiaa/GENIE (official GENIE R-3_06_02 of 2025-07-01 plus the FASER port).
Prepared 2026-10-02.*

## 1. Where the versions sit

| | GENIE base | upstream content |
|---|---|---|
| FASER 3.04 | R-3_04_00 (2022-11-29) | + 168 upstream commits merged in by the FASER branch (up to Sept 2023) |
| new 3.06 | R-3_06_02 (2025-07-01) | 390 further upstream commits (~58 pull requests, Oct 2023 – Jul 2025) |

Overall upstream diff R-3_04_00 → R-3_06_02: ~1480 files (mostly config XML, new physics
modules, and large hadron-tensor data tables for SuSAv2/CRPA).

**Default tune is unchanged:** `G18_02a_00_000`, and its `ModelConfiguration.xml` is identical
apart from the author header. For the default FASER production the physics *choices* are the same;
what changes is the implementation of several components underneath (section 3).

## 2. FASER-specific code: what was ported

The FASER fork consists of 43 commits by Dave Casper. Everything outside `faser/` was carried over:

| item | status in 3.06 |
|---|---|
| `gevgen_faser` (`src/Apps/gFaserEvGen.cxx`), `gmkspl_faser` (`gMakeFaserSplines.cxx`) | ported unchanged |
| `FaserGMCJDriver`, `FaserROOTGeomAnalyzer` | ported unchanged; the GENIE interfaces they use (`GMCJDriver`, `ROOTGeomAnalyzer`, `GFluxI`, `GeomAnalyzerI`) differ only by copyright lines |
| `configure --enable-faser`, `src/Apps/Makefile` targets | ported (applied cleanly) |
| `NaturalIsotopes::GetIsotopeData(pdg)` | re-added (3.06 already has the isotope atomic mass the FASER code needs) |
| `GVLD-Emax` = **7 TeV** in `config/CommonParam.xml` (official: 1 TeV) | re-applied — essential for FASER energies |
| `GSimpleNtpFlux` weighted-flux POT fix (`/ fMaxWeight`) | **already in official 3.06** (upstream PR #280) |
| LinkDef pragmas (`PDGLibrary::Instance`, `PrintBanner`) | ported |
| tune `F23_00a` (G18_02a + GLRES, HENuEl, Photon-RES/COH, HEDIS generators) | ported; its private 3.04-era `CommonParam.xml` dropped so it uses the 3.06 one (it only added unused DIS-join parameters) |
| tune `G25_01a` (local copy of G18_02a, used by `runFASERcal_Gab.sh`) | copied |
| `faser/` (geometries, Aki 2024 fluxes, run/spline scripts, gfaser converter) | copied; Kling 2023 flux ntuples (up to 575 MB) git-ignored, regenerate with the scripts in that folder |
| local edits: `EKineVar : unsigned int`, FASER message streams | ported |
| not ported | the fork's `Make.include` Pythia lines (they broke `-lpythia6` and removed the Pythia8 link block); the `loadlibs.C` `libPythia6`→`libpythia6` rename (not needed on macOS); the global NOTICE→WARN verbosity changes in your local `Messenger.xml` |

## 3. Upstream changes relevant to FASER (high-energy ν, DIS, charm, decays)

- **Pythia6 / Pythia8 refactoring**
  - Pythia6 is now **optional** (`--disable-pythia6`), so a pure-Pythia8 build is possible.
  - Pythia8 uses a proper singleton (`Pythia8Singleton`), and there is a new `Pythia8Decayer2023`.
  - The default decayer switched from `PythiaDecayer` to `Pythia6Decayer2023`, in `UnstableParticleDecayer` and `AGKYLowW2019`.
  - DIS charm hadronization moved from `AGCharm2019` to `AGCharmPythia6Hadro2023`, with an `AGCharmPythia8Hadro2023` alternative. The charm fractions, Peterson fragmentation and pT parameters are identical.
  - HEDIS hadronization is now `LeptoHadPythia6`, with a `LeptoHadPythia8` alternative; Pythia8 output was removed from HEDIS.
  - The high-energy lepton channels (GLRES, Photon-RES/COH) got separate Pythia6 and Pythia8 W-decay classes.
- **Configurable constants:** `FermiConstant` and `FineStructureConstant` are now in `CommonParam.xml`, with the historical GENIE values.
- **Memory-leak fixes** across the event loop, plus a GRV98LO memory leak fix. These matter for long FASER productions.
- **HEDIS:** its configuration now uses a `HEDIS-PYTHIA` parameter set (primordial kT 0.44, remnant pT 0.35).

## 4. Other upstream physics additions (mostly low-energy, not used by default)

- **New tunes**
  - `G24_20i`, `G24_20j`, `G24_20k`, `G24_20l`
  - `N24_20i` (NOvA 2024, based on AR23_20i)
  - `MK19_00a`
- **Single-pion production:** the MK model (`MKSPPPXSec2020`, `SPPEventGenerator`).
- **Quasi-elastic form factors**
  - Z-expansion electric form factors and the Galster model
  - MArun axial form factor, which replaces `KuzminNaumov2016`
  - MK form factors
- **Nuclear models:** SuSAv2/CRPA hadron tensors and electron-scattering updates, a fix for the correlated tail of the local Fermi gas, and FSI fixes (including a Q² feature).
- **Professor2 tuning interface:** now optional.

## 5. Build-system differences

| | FASER 3.04 (old recipe) | 3.06 (new recipe) |
|---|---|---|
| environment | ATLAS container (CentOS 7 via apptainer) + `asetup Athena,22.0.49` | none; conda-forge on macOS, or a plain LCG view on EL9 |
| ROOT | 6.24 (TPythia6 still part of ROOT) | 6.3x/6.40 (TPythia6 removed in 6.32, so it is built ourselves) |
| TPythia6 | Athena/Calypso CMake | plain CMake (`faser/TPythia6_standalone`) |
| Apple Silicon | not supported | supported upstream (#446), plus our `Make.include` patch for conda compilers |
| `ROOTSYS` | required by `configure` | no longer required (#442) |
| Pythia6 link | broken variables in the fork (`-lpythia6` never linked explicitly) | fixed upstream; links `-lPythia6` (the build script provides that name) |
| APFEL | enabled | off by default (`WITH_APFEL=1`); only needed for HEDIS |
| scripts | `ATLAS_container.sh`, `go`, `kk`, `setupGenerator.sh`, `buildGenerator.sh` | `build_genie_{mac,lcg}.sh`, `setup_{mac,lcg}.sh` in the repo top directory |

## 6. What this means for production

1. **Splines must be regenerated** for 3.06 (`faser/Splines/`: `calcSplinesN.sh` → `mergeSplinesN.sh` →
   `calc*SplinesA.sh` → `mergeSplinesA.sh`). The 3.04 `faserSplines.7TeV.xml` is not valid.
2. **Expect small differences in decays and charm hadronization** at the event level. The model
   parameters are the same, but the classes were rewritten. A validation against 3.04 output (e.g. charm
   and τ samples with the same fluxes and geometry) is worthwhile before switching.
3. **Pythia8 hadronization is now a realistic option** (`WITH_PYTHIA8=1`, then select the Pythia8
   variants in the tune). Pythia6 can eventually be dropped.
4. **macOS specifics found while porting** (all handled by the build scripts):
   - **clang version:** conda's `compilers` metapackage pins clang 18, while ROOT 6.40 needs libc++ 20
     headers, so clang is matched to the headers.
   - **NAN/INFINITY:** the macOS 27 SDK takes `NAN`/`INFINITY` from `<float.h>`, which clang 20
     defines only in non-strict mode, so GENIE is compiled with `-std=gnu++20`.
   - **libc++ availability markup:** the markup is disabled (`-D_LIBCPP_DISABLE_AVAILABILITY`).
     `rootcling` gets the same flags.
   - **Externals install path:** GENIE 3.06's `make distclean` empties the install directory,
     so the external libraries are installed elsewhere.
   - **TPythia6 link path:** 3.06 links its libraries with `$(ROOT_LIBRARIES)`, which contains
     `-lEGPythia6` without its path; the `Make.include` patch adds it.
