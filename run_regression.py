#!/usr/bin/env python3
"""
run_regression.py -- generate a few small, fixed-seed GENIE samples with
gevgen_faser and compare them against a stored GOLDEN sample: event
counts, flavours, processes, targets, kinematics, final-state
multiplicities, charm production (and charm decays, if GENIE decays them)
and taus (production and decay modes) -- in the same spirit as the FASER
repository's run_regression_tests.py.

Cases (all with the FASERCal geometry in data/GDML and the faser_xsec
splines):
    light   Aki 2024 light flux       5000 events  seed 2999833
    charm   Aki 2024 charm flux       5000 events  seed 3999833
    nutau   Kling 2021 nu_tau + anti-nu_tau histograms only
                                      2000 events  seed 1999833
They run in parallel (gevgen_faser --gfaser --no-ghep; a few minutes in
total), then each .gfaser.root is turned into a summary:
  - scalars (with statistical errors): fractions and means,
  - histograms (fixed binning, recorded with the golden sample),
  - health checks that must be exactly zero (NaNs, E < m, broken
    mother/daughter indices, events without a primary lepton, ...),
  - an event hash (to tell "bitwise identical" from "statistically equal").

Why statistical, not exact (unlike run_regression_tests.py in FASER):
GENIE samples are exactly reproducible only with the same binary on the
same platform. A different compiler, CPU or ROOT changes floating-point
rounding, one accept/reject decision flips and the sequence of events
diverges (Mac vs Ubuntu: identical for 38 events, then different). So
the comparison is:
  - scalars: pull = (current - golden) / sqrt(err_cur^2 + err_gold^2);
    FAIL above --pull-fail (5), WARN above --pull-warn (3);
  - histograms: chi2 test for two unweighted histograms (shape);
    FAIL below p = --p-fail (1e-4), WARN below --p-warn (1e-2);
  - health checks: must be 0, else FAIL;
  - event hash: reported (identical = same binary/platform as the golden
    sample); with --exact a different hash is a FAIL.
With ~60 histograms and ~100 scalars a WARN now and then is expected
noise; a FAIL, or WARNs that persist with another --seed-offset, is a
real change.

Files (tests/regression/):
    golden/<case>.json         golden summary: metadata, scalars, histograms, health
    golden/<case>.hists.txt    the same histograms, as text for plot_regression.C
    golden/golden_<case>.pdf   the golden histograms (made with --record)
    results/<case>.json        summary of the latest run (any mode)
    results/comparison.csv     every compared quantity: golden, current, pull/p, status
    results/compare_<case>.pdf golden vs current overlays (needs `root`)
    work/                      generated .gfaser.root files and logs (git-ignored)

Needs `source setup.sh` (gevgen_faser and root on PATH). No numpy or
PyROOT needed: the .gfaser.root files are read by tests/regression/
dump_gfaser.C through `root -b -q`.

Usage:
    python3 run_regression.py --record             # make the golden sample (once)
    python3 run_regression.py                      # regenerate and compare to golden
    python3 run_regression.py --case charm         # one case (repeatable)
    python3 run_regression.py --quick              # 5x fewer events (looser test, ~1 min)
    python3 run_regression.py --skip-generate      # re-analyse the last generated files
    python3 run_regression.py --input light=output/fasercal.Aki2024.v10.light.0.gfaser.root
                                                   # check an existing file instead of generating
    python3 run_regression.py --seed-offset 7      # same test, independent events
    python3 run_regression.py --exact              # also require identical events
    python3 run_regression.py --record --force     # overwrite the golden sample (after a
                                                   #   change you have validated!)
    python3 run_regression.py --list
"""
import argparse
import csv
import datetime
import hashlib
import json
import math
import os
import platform
import shutil
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
REG_DIR = REPO_ROOT / "tests" / "regression"
GOLDEN_DIR = REG_DIR / "golden"
RESULTS_DIR = REG_DIR / "results"
WORK_DIR = REG_DIR / "work"
DUMP_MACRO = REG_DIR / "dump_gfaser.C"
PLOT_MACRO = REG_DIR / "plot_regression.C"
SCHEMA_VERSION = 1

# ---------------------------------------------------------------------------
# test cases
# ---------------------------------------------------------------------------
CASES = {
    "light": {"flux": "Aki_2024/events_light_4x4.root", "n_events": 5000, "seed": 2999833,
              "about": "Aki 2024 light-hadron flux (all flavours)"},
    "charm": {"flux": "Aki_2024/events_charm_4x4.root", "n_events": 5000, "seed": 3999833,
              "about": "Aki 2024 charm flux (incl. nu_tau from D_s)"},
    "nutau": {"flux": "Kling_2021/Kling_2021.root,NuTau[16],AntiNuTau[-16]", "n_events": 2000,
              "seed": 1999833, "about": "Kling 2021 nu_tau + anti-nu_tau spectra only"},
}

# ---------------------------------------------------------------------------
# particle bookkeeping
# ---------------------------------------------------------------------------
# GENIE status codes (GHepStatus.h)
ST_INITIAL, ST_FINAL, ST_INTERMEDIATE, ST_DECAYED = 0, 1, 2, 3
ST_HIT_NUCLEON, ST_PREFRAG, ST_RES, ST_IN_NUCLEUS, ST_REMNANT = 11, 12, 13, 14, 15

LEPTONS = {11, 13, 15}
NEUTRINOS = {12, 14, 16}
CHARGED_HADRONS = {211, 321, 2212, 3112, 3222, 3312, 3334, 411, 431, 4122, 4222, 4232, 4332}
CHARM_SPECIES = {421: "D0", 411: "D+", 431: "Ds+", 4122: "Lambdac+", 4222: "Sigmac++",
                 4212: "Sigmac+", 4112: "Sigmac0", 4232: "Xic+", 4132: "Xic0", 4332: "Omegac0",
                 441: "etac", 443: "J/psi"}
CHARM_LABELS = ["D0", "D+", "Ds+", "Lambdac+", "Sigmac", "other"]
TAU_MODES = ["e nu nu", "mu nu nu", "1-prong had", "3-prong had", "other"]
TARGET_Z = {26: "Fe", 74: "W", 82: "Pb", 6: "C", 1: "H", 8: "O", 13: "Al", 14: "Si"}


def is_charm(pdg):
    a = abs(pdg)
    if a in CHARM_SPECIES:
        return True
    # mesons 4xx, baryons 4xxx (PDG numbering), ignore nuclei
    return a < 100000 and ((a // 100) % 10 == 4 or (a // 1000) % 10 == 4)


def charm_label(pdg):
    name = CHARM_SPECIES.get(abs(pdg), "other")
    return "Sigmac" if name.startswith("Sigmac") else (name if name in CHARM_LABELS else "other")


def nucleus_z(pdg):
    """10LZZZAAAI -> Z; free proton/neutron -> 1/0."""
    if pdg >= 1000000000:
        return (pdg // 10000) % 1000
    return 1 if pdg == 2212 else (0 if pdg == 2112 else -1)


# ---------------------------------------------------------------------------
# histograms (pure python, fixed edges, under/overflow kept)
# ---------------------------------------------------------------------------
def lin_edges(lo, hi, n):
    return [lo + (hi - lo) * i / n for i in range(n + 1)]


def log_edges(lo, hi, n):
    return [lo * (hi / lo) ** (i / n) for i in range(n + 1)]


def int_edges(lo, hi):
    return [i - 0.5 for i in range(lo, hi + 2)]


class Hist:
    def __init__(self, name, title, xtitle, edges, labels=None, logx=False):
        self.name, self.title, self.xtitle = name, title, xtitle
        self.edges, self.labels, self.logx = edges, labels, logx
        self.counts = [0] * (len(edges) + 1)        # [underflow, bins..., overflow]

    def fill(self, x):
        if x is None or (isinstance(x, float) and math.isnan(x)):
            return
        e = self.edges
        if x < e[0]:
            self.counts[0] += 1
        elif x >= e[-1]:
            self.counts[-1] += 1
        else:
            lo, hi = 0, len(e) - 1
            while hi - lo > 1:
                mid = (lo + hi) // 2
                if x >= e[mid]:
                    lo = mid
                else:
                    hi = mid
            self.counts[lo + 1] += 1

    def to_json(self):
        return {"title": self.title, "xtitle": self.xtitle, "edges": self.edges,
                "labels": self.labels, "logx": self.logx, "counts": self.counts}


def make_hists():
    H = {}

    def h(name, title, xtitle, edges, labels=None, logx=False):
        H[name] = Hist(name, title, xtitle, edges, labels, logx)
    h("enu", "Neutrino energy", "E_{#nu} [GeV]", log_edges(5, 7000, 30), logx=True)
    h("nu_flavour", "Neutrino flavour", "", int_edges(0, 5),
      labels=["nu_e", "anti-nu_e", "nu_mu", "anti-nu_mu", "nu_tau", "anti-nu_tau"])
    h("process", "Scattering process", "", int_edges(0, 5),
      labels=["CC DIS", "NC DIS", "CC RES", "NC RES", "CC QEL", "other"])
    h("target", "Target nucleus", "", int_edges(0, len(TARGET_Z)),
      labels=list(TARGET_Z.values()) + ["other"])
    h("vx", "Vertex x", "x [m]", lin_edges(-0.5, 1.5, 40))
    h("vy", "Vertex y", "y [m]", lin_edges(-0.75, 1.0, 35))
    h("vz", "Vertex z", "z [m]", lin_edges(0.0, 8.0, 80))
    h("elep_cc", "Primary lepton energy (CC)", "E_{l} [GeV]", log_edges(0.5, 7000, 30), logx=True)
    h("y_cc", "Inelasticity y (CC)", "y", lin_edges(0, 1, 25))
    h("q2_cc", "Q^{2} (CC)", "Q^{2} [GeV^{2}]", log_edges(0.01, 1e4, 30), logx=True)
    h("w_had", "Hadronic invariant mass W", "W [GeV]", log_edges(0.8, 200, 30), logx=True)
    h("theta_lep", "Primary lepton angle (CC)", "#theta_{l} [mrad]", log_edges(0.1, 1000, 30), logx=True)
    h("ehad_vis", "Final-state hadron energy", "#Sigma E_{had} [GeV]", log_edges(0.1, 7000, 30), logx=True)
    h("n_charged", "Charged hadrons (final state)", "N", int_edges(0, 50))
    h("n_pi0", "#pi^{0} (final state)", "N", int_edges(0, 25))
    h("n_gamma", "#gamma (final state)", "N", int_edges(0, 25))
    h("n_neutron", "Neutrons (final state)", "N", int_edges(0, 40))
    h("n_proton", "Protons (final state)", "N", int_edges(0, 40))
    h("n_kaon", "K^{#pm}, K^{0} (final state)", "N", int_edges(0, 10))
    h("n_particles", "Particles in the event record", "N", int_edges(0, 200))
    h("pz_balance", "p_{z}(final) - p_{z}(#nu)", "#Delta p_{z} [GeV]", lin_edges(-2, 2, 40))
    # charm
    h("n_charm", "Charm hadrons per event", "N", int_edges(0, 3))
    h("charm_species", "Charm hadron species", "", int_edges(0, len(CHARM_LABELS) - 1),
      labels=CHARM_LABELS)
    h("charm_e", "Charm hadron energy", "E_{c} [GeV]", log_edges(1, 7000, 30), logx=True)
    h("charm_z", "Charm energy fraction z = E_{c}/#nu", "z", lin_edges(0, 1, 20))
    h("charm_pt", "Charm hadron p_{T}", "p_{T} [GeV]", lin_edges(0, 5, 25))
    h("charm_decay_ndau", "Charm decay: daughters", "N", int_edges(0, 8))
    h("charm_decay_nprong", "Charm decay: charged daughters", "N", int_edges(0, 7))
    h("charm_decay_lep", "Charm decay: lepton", "", int_edges(0, 2),
      labels=["hadronic", "e", "mu"])
    # tau
    h("tau_e", "#tau energy", "E_{#tau} [GeV]", log_edges(1, 7000, 30), logx=True)
    h("tau_pt", "#tau p_{T}", "p_{T} [GeV]", lin_edges(0, 5, 25))
    h("tau_decay_mode", "#tau decay mode", "", int_edges(0, len(TAU_MODES) - 1), labels=TAU_MODES)
    h("tau_decay_nprong", "#tau decay: charged daughters", "N", int_edges(0, 7))
    h("tau_vis_frac", "#tau decay: visible energy fraction", "E_{vis}/E_{#tau}", lin_edges(0, 1, 20))
    return H


# ---------------------------------------------------------------------------
# summary of one .gfaser.root file
# ---------------------------------------------------------------------------
class Mean:
    def __init__(self):
        self.n = 0; self.s = 0.0; self.s2 = 0.0

    def add(self, x):
        if x is None or (isinstance(x, float) and (math.isnan(x) or math.isinf(x))):
            return
        self.n += 1; self.s += x; self.s2 += x * x

    def result(self):
        if self.n == 0:
            return {"value": None, "error": None, "n": 0}
        m = self.s / self.n
        var = max(self.s2 / self.n - m * m, 0.0)
        return {"value": m, "error": math.sqrt(var / self.n) if self.n > 1 else 0.0, "n": self.n}


def frac(k, n):
    if n == 0:
        return {"value": None, "error": None, "n": 0}
    p = k / n
    # binomial error, never exactly 0 (so a 0 -> 1 event change is not an infinite pull)
    err = math.sqrt(max(p * (1 - p), 1.0 / n) / n)
    return {"value": p, "error": err, "n": n}


def parse_event(line):
    head, _, rest = line.partition("|")
    vx, vy, vz, n = head.split()
    parts = []
    for chunk in rest.split(";"):
        f = chunk.split()
        if len(f) != 11:
            continue
        parts.append((int(f[0]), int(f[1]), int(f[2]), int(f[3]), int(f[4]), int(f[5]),
                      float(f[6]), float(f[7]), float(f[8]), float(f[9]), float(f[10])))
    return float(vx), float(vy), float(vz), int(n), parts


def summarize(dump_path: Path, case: str):
    H = make_hists()
    means = {k: Mean() for k in ("enu", "elep_cc", "y_cc", "q2_cc", "w_had", "ehad_vis",
                                 "n_charged", "n_pi0", "n_gamma", "n_neutron", "n_proton",
                                 "n_kaon", "vz", "vx", "vy", "pz_balance",
                                 "charm_e", "charm_z", "charm_pt", "tau_e", "tau_vis_frac")}
    cnt = Counter()
    health = Counter()
    hasher_all = hashlib.sha256()
    hasher_100 = hashlib.sha256()
    weight, n_events = 0.0, 0

    with open(dump_path) as f:
        first = f.readline()
        if first.startswith("#weight"):
            toks = first.split()
            weight = float(toks[1])
        for iev, line in enumerate(f):
            hasher_all.update(line.encode())
            if iev < 100:
                hasher_100.update(line.encode())
            vx, vy, vz, n, P = parse_event(line)
            n_events += 1
            # ---- health checks (must stay zero)
            if any(math.isnan(x) or math.isinf(x) for p in P for x in p[6:]) or \
               any(math.isnan(x) for x in (vx, vy, vz)):
                health["nan_or_inf"] += 1
            if n != len(P):
                health["n_mismatch"] += 1
            for p in P:
                pdg, st, fm, lm, fd, ld, px, py, pz, E, m = p
                if st == ST_FINAL and E < 0:
                    health["negative_energy"] += 1
                if st == ST_FINAL and abs(pdg) < 1000000000 and E < m - 1e-3 * max(1.0, m):
                    health["final_E_below_mass"] += 1
                for idx in (fm, lm, fd, ld):
                    if idx < -1 or idx >= len(P):
                        health["bad_index"] += 1
            if not P or abs(P[0][0]) not in NEUTRINOS or P[0][1] != ST_INITIAL:
                health["first_particle_not_initial_neutrino"] += 1
                continue

            nu = P[0]
            nupdg, enu = nu[0], nu[9]
            # target: second initial-state particle
            tgt = next((p for p in P[1:3] if p[1] == ST_INITIAL), None)
            # primary lepton: final/decayed lepton or neutrino whose mother is the neutrino
            lep = next((p for p in P[1:] if p[2] == 0 and abs(p[0]) in LEPTONS | NEUTRINOS), None)
            if lep is None:
                health["no_primary_lepton"] += 1
                continue
            cc = abs(lep[0]) in LEPTONS
            hit = next((p for p in P if p[1] == ST_HIT_NUCLEON), None)
            res = any(p[1] == ST_RES for p in P)
            dis = any(p[1] == ST_PREFRAG for p in P)
            finals = [p for p in P if p[1] == ST_FINAL and abs(p[0]) < 1000000000]

            # ---- event-level
            cnt["events"] += 1
            cnt["cc"] += cc
            cnt[f"nu_{nupdg}"] += 1
            z = nucleus_z(tgt[0]) if tgt else -1
            cnt[f"target_{TARGET_Z.get(z, 'other')}"] += 1
            proc = ("DIS" if dis else "RES" if res else "QEL/other")
            cnt[f"proc_{'CC' if cc else 'NC'}_{proc}"] += 1
            means["enu"].add(enu)
            means["vx"].add(vx); means["vy"].add(vy); means["vz"].add(vz)
            H["enu"].fill(enu)
            H["nu_flavour"].fill({12: 0, -12: 1, 14: 2, -14: 3, 16: 4, -16: 5}.get(nupdg, -1))
            H["process"].fill({("CC", "DIS"): 0, ("NC", "DIS"): 1, ("CC", "RES"): 2,
                               ("NC", "RES"): 3, ("CC", "QEL/other"): 4}.get(
                                   ("CC" if cc else "NC", proc), 5))
            tz = list(TARGET_Z).index(z) if z in TARGET_Z else len(TARGET_Z)
            H["target"].fill(tz)
            H["vx"].fill(vx); H["vy"].fill(vy); H["vz"].fill(vz)
            H["n_particles"].fill(len(P))

            # kinematics from neutrino and primary lepton
            q = (nu[6] - lep[6], nu[7] - lep[7], nu[8] - lep[8], nu[9] - lep[9])
            Q2 = -(q[3] ** 2 - q[0] ** 2 - q[1] ** 2 - q[2] ** 2)
            if cc:
                y = 1.0 - lep[9] / enu if enu > 0 else float("nan")
                means["elep_cc"].add(lep[9]); means["y_cc"].add(y); means["q2_cc"].add(Q2)
                H["elep_cc"].fill(lep[9]); H["y_cc"].fill(y); H["q2_cc"].fill(Q2)
                pl = math.sqrt(lep[6] ** 2 + lep[7] ** 2 + lep[8] ** 2)
                if pl > 0:
                    H["theta_lep"].fill(1000.0 * math.acos(max(-1.0, min(1.0, lep[8] / pl))))
            if hit is not None:
                Wx, Wy, Wz, WE = q[0] + hit[6], q[1] + hit[7], q[2] + hit[8], q[3] + hit[9]
                W2 = WE * WE - Wx * Wx - Wy * Wy - Wz * Wz
                if W2 > 0:
                    means["w_had"].add(math.sqrt(W2)); H["w_had"].fill(math.sqrt(W2))

            # final-state multiplicities and energy
            nch = sum(1 for p in finals if abs(p[0]) in CHARGED_HADRONS)
            npi0 = sum(1 for p in finals if p[0] == 111)
            ngam = sum(1 for p in finals if p[0] == 22)
            nneu = sum(1 for p in finals if p[0] == 2112)
            npro = sum(1 for p in finals if p[0] == 2212)
            nkao = sum(1 for p in finals if abs(p[0]) in (321, 311, 130, 310))
            ehad = sum(p[9] for p in finals if abs(p[0]) not in LEPTONS | NEUTRINOS)
            for k, v in (("n_charged", nch), ("n_pi0", npi0), ("n_gamma", ngam),
                         ("n_neutron", nneu), ("n_proton", npro), ("n_kaon", nkao)):
                means[k].add(v); H[k].fill(v)
            means["ehad_vis"].add(ehad); H["ehad_vis"].fill(ehad)
            dpz = sum(p[8] for p in P if p[1] == ST_FINAL) - nu[8]
            means["pz_balance"].add(dpz); H["pz_balance"].fill(dpz)

            # ---- charm: final-state (status 1) or decayed (status 3) charm hadrons
            nu_ = enu - lep[9]
            charm = [p for p in P if p[1] in (ST_FINAL, ST_DECAYED) and is_charm(p[0])]
            H["n_charm"].fill(len(charm))
            if charm:
                cnt["charm_events"] += 1
            for c in charm:
                cnt["charm_hadrons"] += 1
                lab = charm_label(c[0])
                cnt[f"charm_{lab}"] += 1
                cnt["charm_anti"] += c[0] < 0
                H["charm_species"].fill(CHARM_LABELS.index(lab))
                pt = math.hypot(c[6], c[7])
                means["charm_e"].add(c[9]); H["charm_e"].fill(c[9])
                means["charm_pt"].add(pt); H["charm_pt"].fill(pt)
                if nu_ > 0:
                    means["charm_z"].add(c[9] / nu_); H["charm_z"].fill(c[9] / nu_)
                if c[1] == ST_DECAYED and 0 <= c[4] <= c[5] < len(P):
                    cnt["charm_decayed"] += 1
                    dau = P[c[4]:c[5] + 1]
                    H["charm_decay_ndau"].fill(len(dau))
                    H["charm_decay_nprong"].fill(sum(1 for d in dau if abs(d[0]) in CHARGED_HADRONS | LEPTONS))
                    lepd = next((abs(d[0]) for d in dau if abs(d[0]) in (11, 13)), None)
                    H["charm_decay_lep"].fill({None: 0, 11: 1, 13: 2}[lepd])
                    cnt[f"charm_decay_{ {None: 'had', 11: 'e', 13: 'mu'}[lepd] }"] += 1

            # ---- taus
            taus = [p for p in P if abs(p[0]) == 15 and p[1] in (ST_FINAL, ST_DECAYED)]
            for t in taus:
                cnt["taus"] += 1
                cnt[f"tau_status_{t[1]}"] += 1
                pt = math.hypot(t[6], t[7])
                means["tau_e"].add(t[9]); H["tau_e"].fill(t[9]); H["tau_pt"].fill(pt)
                if t[1] == ST_DECAYED and 0 <= t[4] <= t[5] < len(P):
                    dau = P[t[4]:t[5] + 1]
                    ids = [abs(d[0]) for d in dau]
                    nprong = sum(1 for d in dau if abs(d[0]) in CHARGED_HADRONS | LEPTONS)
                    if 11 in ids:
                        mode = 0
                    elif 13 in ids:
                        mode = 1
                    elif nprong == 1:
                        mode = 2
                    elif nprong == 3:
                        mode = 3
                    else:
                        mode = 4
                    cnt[f"tau_mode_{TAU_MODES[mode]}"] += 1
                    H["tau_decay_mode"].fill(mode)
                    H["tau_decay_nprong"].fill(nprong)
                    evis = sum(d[9] for d in dau if abs(d[0]) not in NEUTRINOS)
                    if t[9] > 0:
                        means["tau_vis_frac"].add(evis / t[9]); H["tau_vis_frac"].fill(evis / t[9])

    # ---- assemble
    N = cnt["events"]
    S = {}
    S["frac_cc"] = frac(cnt["cc"], N)
    for pdg, name in ((12, "nue"), (-12, "nuebar"), (14, "numu"), (-14, "numubar"),
                      (16, "nutau"), (-16, "nutaubar")):
        S[f"frac_{name}"] = frac(cnt[f"nu_{pdg}"], N)
    for name in list(TARGET_Z.values()) + ["other"]:
        S[f"frac_target_{name}"] = frac(cnt[f"target_{name}"], N)
    for cur in ("CC", "NC"):
        for proc in ("DIS", "RES", "QEL/other"):
            S[f"frac_{cur}_{proc.replace('/', '_')}"] = frac(cnt[f"proc_{cur}_{proc}"], N)
    for k, m in means.items():
        S[f"mean_{k}"] = m.result()
    nc = cnt["charm_hadrons"]
    S["frac_charm_events"] = frac(cnt["charm_events"], N)
    for lab in CHARM_LABELS:
        S[f"charm_frac_{lab}"] = frac(cnt[f"charm_{lab}"], nc)
    S["charm_frac_anti"] = frac(cnt["charm_anti"], nc)
    S["charm_frac_decayed"] = frac(cnt["charm_decayed"], nc)
    nt = cnt["taus"]
    S["frac_tau_events"] = frac(nt, N)
    S["tau_frac_decayed"] = frac(cnt[f"tau_status_{ST_DECAYED}"], nt)
    ntd = cnt[f"tau_status_{ST_DECAYED}"]
    for mode in TAU_MODES:
        S[f"tau_frac_{mode.replace(' ', '_')}"] = frac(cnt[f"tau_mode_{mode}"], ntd)

    return {
        "schema": SCHEMA_VERSION,
        "case": case,
        "n_events": n_events,
        "n_analysed": N,
        "tree_weight": weight,
        "counts": dict(sorted(cnt.items())),
        "scalars": S,
        "histograms": {k: h.to_json() for k, h in H.items()},
        "health": {k: health.get(k, 0) for k in ("nan_or_inf", "n_mismatch", "negative_energy",
                                                  "final_E_below_mass", "bad_index",
                                                  "first_particle_not_initial_neutrino",
                                                  "no_primary_lepton")},
        "event_hash_first100": hasher_100.hexdigest(),
        "event_hash_all": hasher_all.hexdigest(),
    }


# ---------------------------------------------------------------------------
# statistics: chi2 test of two unweighted histograms
# ---------------------------------------------------------------------------
def _gammainc_upper_reg(a, x):
    """Q(a, x) = Gamma(a, x) / Gamma(a), regularized upper incomplete gamma."""
    if x <= 0:
        return 1.0
    if x < a + 1:          # series for P, Q = 1 - P
        term = s = 1.0 / a
        ap = a
        for _ in range(1000):
            ap += 1
            term *= x / ap
            s += term
            if abs(term) < abs(s) * 1e-15:
                break
        return max(0.0, 1.0 - s * math.exp(-x + a * math.log(x) - math.lgamma(a)))
    # continued fraction for Q (Lentz)
    tiny = 1e-300
    b = x + 1 - a; c = 1 / tiny; d = 1 / b; h = d
    for i in range(1, 1000):
        an = -i * (i - a); b += 2
        d = an * d + b; d = tiny if abs(d) < tiny else d
        c = b + an / c; c = tiny if abs(c) < tiny else c
        d = 1 / d; delta = d * c; h *= delta
        if abs(delta - 1) < 1e-15:
            break
    return h * math.exp(-x + a * math.log(x) - math.lgamma(a))


def chi2_two_hists(c1, c2):
    """Shape comparison of two unweighted histograms (NIST / ROOT 'UU'):
    chi2 = sum (sqrt(N2/N1) n1 - sqrt(N1/N2) n2)^2 / (n1 + n2). Returns
    (chi2, ndf, p)."""
    N1, N2 = sum(c1), sum(c2)
    if N1 == 0 or N2 == 0:
        return 0.0, 0, 1.0 if N1 == N2 else 0.0
    r12, r21 = math.sqrt(N2 / N1), math.sqrt(N1 / N2)
    chi2, nb = 0.0, 0
    for a, b in zip(c1, c2):
        if a + b > 0:
            chi2 += (r12 * a - r21 * b) ** 2 / (a + b)
            nb += 1
    ndf = nb - 1
    if ndf <= 0:
        return chi2, ndf, 1.0
    return chi2, ndf, _gammainc_upper_reg(ndf / 2.0, chi2 / 2.0)


# ---------------------------------------------------------------------------
# comparison
# ---------------------------------------------------------------------------
def compare(cur, gold, args):
    rows = []

    def row(kind, name, g, c, metric, status, note=""):
        rows.append({"case": cur["case"], "kind": kind, "name": name, "golden": g, "current": c,
                     "metric": metric, "status": status, "note": note})

    # health: exact
    for k, v in cur["health"].items():
        g = gold.get("health", {}).get(k, 0)
        row("health", k, g, v, "", "PASS" if v == 0 else "FAIL", "must be 0")
    # event count: fixed by -n for generated samples, Poisson for given files
    if cur.get("meta", {}).get("n_requested") and gold.get("meta", {}).get("n_requested"):
        st = "PASS" if cur["n_events"] == gold["n_events"] else "FAIL"
        row("count", "n_events", gold["n_events"], cur["n_events"], "", st, "set by -n")
    else:
        ng, nc = gold["n_events"], cur["n_events"]
        pull = (nc - ng) / math.sqrt(max(ng + nc, 1))
        st = "FAIL" if abs(pull) > args.pull_fail else "WARN" if abs(pull) > args.pull_warn else "PASS"
        row("count", "n_events", ng, nc, f"pull={pull:+.2f}", st, "Poisson (input files)")
    # scalars: pulls
    for k, g in gold["scalars"].items():
        c = cur["scalars"].get(k)
        if c is None:
            row("scalar", k, g["value"], None, "", "FAIL", "missing in current")
            continue
        if g["value"] is None and c["value"] is None:
            row("scalar", k, None, None, "", "PASS", "empty in both")
            continue
        if g["value"] is None or c["value"] is None:
            # appears/disappears: a real change unless both samples are tiny
            st = "WARN" if max(g.get("n", 0), c.get("n", 0)) < 20 else "FAIL"
            row("scalar", k, g["value"], c["value"], "", st, "present in only one sample")
            continue
        err = math.hypot(g["error"] or 0.0, c["error"] or 0.0)
        if err == 0:
            pull = 0.0 if g["value"] == c["value"] else float("inf")
        else:
            pull = (c["value"] - g["value"]) / err
        st = "FAIL" if abs(pull) > args.pull_fail else "WARN" if abs(pull) > args.pull_warn else "PASS"
        row("scalar", k, g["value"], c["value"], f"pull={pull:+.2f}", st)
    # histograms: chi2 shape test
    for k, g in gold["histograms"].items():
        c = cur["histograms"].get(k)
        if c is None or len(c["counts"]) != len(g["counts"]) or c["edges"] != g["edges"]:
            row("hist", k, "", "", "", "FAIL", "missing or different binning (re-record golden?)")
            continue
        if sum(g["counts"]) < 20 and sum(c["counts"]) < 20:
            row("hist", k, sum(g["counts"]), sum(c["counts"]), "", "PASS", "too few entries to test")
            continue
        chi2, ndf, p = chi2_two_hists(g["counts"], c["counts"])
        st = "FAIL" if p < args.p_fail else "WARN" if p < args.p_warn else "PASS"
        row("hist", k, sum(g["counts"]), sum(c["counts"]), f"chi2/ndf={chi2:.1f}/{ndf} p={p:.3g}", st)
    # event hash
    same = cur["event_hash_all"] == gold["event_hash_all"]
    same100 = cur["event_hash_first100"] == gold["event_hash_first100"]
    note = ("bitwise identical events" if same else
            "first 100 events identical, then different" if same100 else
            "different events (expected on another platform/build)")
    row("events", "event_hash", gold["event_hash_all"][:12], cur["event_hash_all"][:12], "",
        ("PASS" if same else "FAIL") if args.exact else "INFO", note)
    return rows


# ---------------------------------------------------------------------------
# running
# ---------------------------------------------------------------------------
def tag(msg=""):
    print(f"[run_regression] {msg}", flush=True)


def genie_home():
    return Path(os.environ.get("GENIE_HOME", str(REPO_ROOT)))


def geometry_file(args):
    if args.geometry_file:
        return args.geometry_file.resolve()
    gd = genie_home() / "data" / "GDML"
    g = sorted(gd.glob("*.gdml"))
    if len(g) != 1:
        sys.exit(f"error: need exactly one .gdml in {gd} (found {len(g)}); use --geometry-file")
    return g[0].resolve()


def splines_file(args):
    s = args.splines or (genie_home() / "faser_xsec" / "faserSplines.7TeV.xml")
    return s if s.is_absolute() else (Path.cwd() / s)


def file_digest(path: Path, nbytes=None):
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            if nbytes:
                h.update(f.read(nbytes))
            else:
                for chunk in iter(lambda: f.read(1 << 20), b""):
                    h.update(chunk)
        return h.hexdigest()[:16]
    except OSError:
        return None


def git_describe():
    try:
        return subprocess.run(["git", "-C", str(REPO_ROOT), "describe", "--always", "--dirty"],
                              capture_output=True, text=True, timeout=10).stdout.strip() or None
    except Exception:
        return None


def build_command(case, cfg, args, geometry, splines, n_events, seed):
    flux = cfg["flux"]
    head, sep, tail = flux.partition(",")
    flux_arg = str(genie_home() / "data" / "fluxes" / head) + (sep + tail if sep else "")
    cmd = ["gevgen_faser", "-n", str(n_events), "-r", "0", "-g", str(geometry), "-f", flux_arg,
           "--seed", str(seed), "--cross-sections", str(splines), "-o", f"regression.{case}",
           "--gfaser", "--no-ghep", "--output-dir", str(WORK_DIR)]
    if args.tune:
        cmd += ["--tune", args.tune]
    return cmd


def generate(cases, args, geometry, splines):
    """Run gevgen_faser for all cases in parallel; returns {case: info}."""
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    info, procs = {}, {}
    for case in cases:
        cfg = CASES[case]
        n_events = max(1, cfg["n_events"] // (5 if args.quick else 1))
        seed = cfg["seed"] + args.seed_offset
        cmd = build_command(case, cfg, args, geometry, splines, n_events, seed)
        gf = WORK_DIR / f"regression.{case}.0.gfaser.root"
        if gf.exists():
            gf.unlink()
        log = open(WORK_DIR / f"regression.{case}.log", "w")
        log.write("# " + " ".join(cmd) + "\n"); log.flush()
        tag(f"{case}: generating {n_events} events (seed {seed}), log: work/{Path(log.name).name}")
        procs[case] = (subprocess.Popen(cmd, cwd=WORK_DIR, stdout=log, stderr=subprocess.STDOUT),
                       log, time.time())
        info[case] = {"command": cmd, "n_requested": n_events, "seed": seed, "gfaser": gf}
    for case, (p, log, t0) in procs.items():
        rc = p.wait()
        log.close()
        info[case]["seconds"] = time.time() - t0
        info[case]["returncode"] = rc
        if rc != 0 or not info[case]["gfaser"].exists():
            tail = Path(log.name).read_text(errors="replace").splitlines()[-25:]
            tag(f"{case}: gevgen_faser FAILED (exit {rc}); last lines of the log:")
            for l in tail:
                print("    " + l)
        else:
            tag(f"{case}: done in {info[case]['seconds'] / 60:.1f} min")
    return info


def dump(gfaser: Path, out_txt: Path):
    root = shutil.which("root")
    if root is None:
        sys.exit("error: `root` not on PATH (source setup.sh)")
    macro = f'{DUMP_MACRO}("{gfaser}","{out_txt}")'
    r = subprocess.run([root, "-l", "-b", "-q", macro], capture_output=True, text=True)
    if r.returncode != 0 or not out_txt.exists():
        sys.exit(f"error: dump_gfaser.C failed for {gfaser}:\n{r.stdout}\n{r.stderr}")


def write_hist_text(summary, path: Path):
    """Histograms as text for plot_regression.C:
    name|title|xtitle|logx|labels(;)|edges(,)|counts(,)"""
    with open(path, "w") as f:
        for k, h in summary["histograms"].items():
            labels = ";".join(h["labels"]) if h["labels"] else "-"
            f.write("|".join([k, h["title"], h["xtitle"] or "-", "1" if h["logx"] else "0", labels,
                              ",".join(f"{e:.10g}" for e in h["edges"]),
                              ",".join(str(c) for c in h["counts"])]) + "\n")


def plot(current_txt, golden_txt, pdf, title):
    root = shutil.which("root")
    if root is None:
        tag("skipping plots: `root` not on PATH")
        return
    macro = f'{PLOT_MACRO}("{current_txt}","{golden_txt}","{pdf}","{title}")'
    r = subprocess.run([root, "-l", "-b", "-q", macro], capture_output=True, text=True)
    if r.returncode != 0:
        tag(f"warning: plot_regression.C failed:\n{r.stdout[-2000:]}\n{r.stderr[-2000:]}")
    else:
        tag(f"plots: {pdf.relative_to(REPO_ROOT)}")


# ---------------------------------------------------------------------------
def parse_args():
    p = argparse.ArgumentParser(description="GENIE (FASER) regression test against a golden sample.",
                                formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    p.add_argument("--case", action="append", dest="cases", choices=sorted(CASES),
                   help="Restrict to this case (repeatable). Default: all.")
    p.add_argument("--record", action="store_true",
                   help="Write the golden sample instead of comparing (refuses to overwrite "
                        "without --force).")
    p.add_argument("--force", action="store_true", help="With --record: overwrite existing golden files.")
    p.add_argument("--quick", action="store_true", help="5x fewer events (statistically looser).")
    p.add_argument("--seed-offset", type=int, default=0,
                   help="Added to every case's seed: same test, independent events.")
    p.add_argument("--skip-generate", action="store_true",
                   help="Reuse the .gfaser.root files already in tests/regression/work.")
    p.add_argument("--input", action="append", default=[], metavar="CASE=FILE",
                   help="Check this existing .gfaser.root file as CASE instead of generating.")
    p.add_argument("--exact", action="store_true",
                   help="Also require bitwise-identical events (same binary and platform).")
    p.add_argument("--pull-warn", type=float, default=3.0)
    p.add_argument("--pull-fail", type=float, default=5.0)
    p.add_argument("--p-warn", type=float, default=1e-2)
    p.add_argument("--p-fail", type=float, default=1e-4)
    p.add_argument("--geometry-file", type=Path, default=None)
    p.add_argument("--splines", type=Path, default=None)
    p.add_argument("--tune", default=None)
    p.add_argument("--no-plots", action="store_true", help="Do not make PDF plots.")
    p.add_argument("--verbose", "-v", action="store_true", help="Print every compared quantity.")
    p.add_argument("--list", action="store_true", help="List the cases and exit.")
    a = p.parse_args()
    a.inputs = {}
    for item in a.input:
        case, _, path = item.partition("=")
        if case not in CASES or not path:
            p.error(f"--input expects CASE=FILE with CASE in {sorted(CASES)}")
        a.inputs[case] = Path(path).resolve()
    return a


def main():
    args = parse_args()
    if args.list:
        for k, c in CASES.items():
            print(f"{k:6s} {c['n_events']:6d} events  seed {c['seed']}  {c['about']}")
        return 0
    cases = args.cases or (sorted(args.inputs) if args.inputs else list(CASES))

    if not args.record:
        missing = [c for c in cases if not (GOLDEN_DIR / f"{c}.json").exists()]
        if missing:
            sys.exit(f"error: no golden sample for {missing}: run with --record first")
    else:
        existing = [c for c in cases if (GOLDEN_DIR / f"{c}.json").exists()]
        if existing and not args.force:
            sys.exit(f"error: golden sample exists for {existing}; add --force to overwrite "
                     f"(only after validating the change!)")
        if args.quick or args.seed_offset or args.inputs:
            tag("warning: recording a golden sample with --quick/--seed-offset/--input: "
                "later default runs will be compared to it")

    geometry, splines = geometry_file(args), splines_file(args)
    meta_common = {
        "date": datetime.datetime.now().isoformat(timespec="seconds"),
        "host": platform.node(), "platform": f"{platform.system()} {platform.machine()}",
        "git": git_describe(),
        "genie_version": (genie_home() / "GenieGenerator" / "VERSION").read_text().strip()
        if (genie_home() / "GenieGenerator" / "VERSION").exists() else None,
        "geometry": str(geometry), "geometry_sha": file_digest(geometry),
        "splines": str(splines.resolve()) if splines.exists() else str(splines),
        "splines_sha": file_digest(splines, nbytes=50_000_000),
        "tune": args.tune,
    }

    # ---- generate (or take inputs)
    to_generate = [c for c in cases if c not in args.inputs]
    gen_info = {}
    if to_generate and not args.skip_generate:
        if shutil.which("gevgen_faser") is None:
            sys.exit("error: gevgen_faser not on PATH (source setup.sh)")
        if not splines.exists():
            sys.exit(f"error: splines not found: {splines}")
        gen_info = generate(to_generate, args, geometry, splines)
    for c in to_generate:
        gen_info.setdefault(c, {"gfaser": WORK_DIR / f"regression.{c}.0.gfaser.root"})
    for c, path in args.inputs.items():
        gen_info[c] = {"gfaser": path, "input_file": str(path)}

    # ---- summarize, record or compare
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    all_rows, verdicts = [], {}
    for case in cases:
        gi = gen_info[case]
        if not Path(gi["gfaser"]).exists():
            tag(f"{case}: no .gfaser.root file ({gi['gfaser']}) -- FAIL")
            verdicts[case] = "FAIL"
            continue
        txt = WORK_DIR / f"regression.{case}.dump.txt"
        WORK_DIR.mkdir(parents=True, exist_ok=True)
        dump(Path(gi["gfaser"]), txt)
        summary = summarize(txt, case)
        meta = dict(meta_common)
        meta.update({"about": CASES[case]["about"],
                     "command": " ".join(gi["command"]) if "command" in gi else None,
                     "seed": gi.get("seed"), "n_requested": gi.get("n_requested"),
                     "seconds": gi.get("seconds"),
                     "seconds_per_event": (gi["seconds"] / summary["n_events"])
                     if gi.get("seconds") and summary["n_events"] else None,
                     "input_file": gi.get("input_file"),
                     "quick": args.quick, "seed_offset": args.seed_offset})
        summary["meta"] = meta
        (RESULTS_DIR / f"{case}.json").write_text(json.dumps(summary, indent=1))
        write_hist_text(summary, RESULTS_DIR / f"{case}.hists.txt")

        if args.record:
            GOLDEN_DIR.mkdir(parents=True, exist_ok=True)
            (GOLDEN_DIR / f"{case}.json").write_text(json.dumps(summary, indent=1))
            write_hist_text(summary, GOLDEN_DIR / f"{case}.hists.txt")
            tag(f"{case}: golden sample recorded ({summary['n_events']} events, "
                f"{sum(summary['health'].values())} health problems)")
            if not args.no_plots:
                plot(GOLDEN_DIR / f"{case}.hists.txt", "-", GOLDEN_DIR / f"golden_{case}.pdf",
                     f"golden {case}")
            verdicts[case] = "RECORDED" if sum(summary["health"].values()) == 0 else "RECORDED (health!)"
            continue

        gold = json.loads((GOLDEN_DIR / f"{case}.json").read_text())
        if gold.get("schema") != SCHEMA_VERSION:
            tag(f"{case}: golden schema {gold.get('schema')} != {SCHEMA_VERSION}: re-record it")
        gm = gold.get("meta", {})
        for key in ("splines_sha", "geometry_sha", "tune"):
            if gm.get(key) != meta.get(key):
                tag(f"{case}: note: {key} differs from the golden sample "
                    f"({gm.get(key)} -> {meta.get(key)}): differences may be expected")
        if gm.get("quick") != args.quick and not args.inputs:
            tag(f"{case}: note: golden made with quick={gm.get('quick')}, now quick={args.quick}")
        rows = compare(summary, gold, args)
        all_rows += rows
        n = Counter(r["status"] for r in rows)
        verdict = "FAIL" if n["FAIL"] else "WARN" if n["WARN"] else "PASS"
        verdicts[case] = verdict
        tag(f"{case}: {verdict}  ({n['PASS']} pass, {n['WARN']} warn, {n['FAIL']} fail; "
            f"{summary['n_events']} events; {next(r['note'] for r in rows if r['name'] == 'event_hash')})")
        for r in rows:
            if r["status"] in ("WARN", "FAIL") or args.verbose:
                g = f"{r['golden']:.6g}" if isinstance(r["golden"], float) else r["golden"]
                c = f"{r['current']:.6g}" if isinstance(r["current"], float) else r["current"]
                tag(f"    {r['status']:4s} {r['kind']:6s} {r['name']:<28s} golden={g} current={c} "
                    f"{r['metric']} {r['note']}")
        if gm.get("seconds_per_event") and meta.get("seconds_per_event"):
            ratio = meta["seconds_per_event"] / gm["seconds_per_event"]
            tag(f"    speed: {meta['seconds_per_event']:.4f} s/event ({ratio:.2f}x golden, "
                f"golden on {gm.get('host')})")
        if not args.no_plots:
            plot(RESULTS_DIR / f"{case}.hists.txt", GOLDEN_DIR / f"{case}.hists.txt",
                 RESULTS_DIR / f"compare_{case}.pdf", f"{case}: current vs golden")

    if all_rows:
        with open(RESULTS_DIR / "comparison.csv", "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(all_rows[0]))
            w.writeheader()
            w.writerows(all_rows)
        tag(f"all compared quantities: {(RESULTS_DIR / 'comparison.csv').relative_to(REPO_ROOT)}")

    tag("=" * 50)
    for case, v in verdicts.items():
        tag(f"  {case:6s} {v}")
    tag("=" * 50)
    return 1 if any(v == "FAIL" for v in verdicts.values()) else 0


if __name__ == "__main__":
    sys.exit(main())
