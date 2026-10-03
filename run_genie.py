#!/usr/bin/env python3
"""
run_genie.py -- run GENIE's `gevgen_faser` for FASER with named,
auto-discovered arguments, split into parallel jobs, with a run plan,
live progress and a run summary -- in the same spirit as the FASER
repository's run_convertgenie.py / run_faserps.py.

Why: the faser/run*.sh scripts are hand-written gevgen_faser command
lines (one per job, with hand-picked run numbers and seeds), easy to get
subtly wrong -- a reused seed or run number silently duplicates events or
overwrites another job's files -- and nothing records afterwards which
luminosity, flux, geometry and splines a sample was made with. This
script builds those command lines for you:

  - finds the inputs: the geometry is the single *.gdml file under
    $GENIE_HOME/data/GDML (override with --geometry-file); the flux is
    picked by name (--flux light|charm -> data/fluxes/Aki_2024/
    events_<flux>_4x4.root, or any file via --flux-file); the splines
    default to $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml;
  - splits the requested luminosity over --jobs parallel jobs (run
    numbers --run, --run+1, ...; seed = --seed + run number, so every job
    and every run number gets its own seed), each at --lumi/--jobs fb^-1,
    running at most --max-parallel at a time (default: number of CPUs);
  - writes everything to the output directory ($GENIE_OUTPUT, i.e.
    GENIE3.06/output, unless --output-dir): the .ghep.root and, by default,
    the .gfaser.root files (gevgen_faser --gfaser; --no-gfaser to skip,
    --cc-only for CC events only in the gFaser file), one log per job, the
    genie-mcjob-<run>.status files;
  - records the exact commands in <prefix>.r<runs>.run_genie.sh next to the
    output, so the luminosity each file was generated at can be found
    again later (run_convertgenie.py scans *.sh files next to the GENIE
    files for "gevgen_faser -l <lumi> ... -o <prefix>");
  - asks before overwriting existing output files with the same prefix
    and run numbers (--force to skip the question);
  - shows a progress line while the jobs run (from the status files),
    and at the end writes <prefix>.r<runs>.run_genie_summary.log with the number
    of events per job, the time per event and the totals;
  - optionally merges the gFaser files with hadd (--merge) and copies the
    gFaser files plus the .sh record to the FASER data area
    (--export, default destination $FASERDATA/GENIE).

Needs `source setup.sh` first (gevgen_faser on PATH, GENIE_HOME set).

Usage:
    python3 run_genie.py                                   # 1000 fb^-1 light, 1 job
    python3 run_genie.py --flux charm
    python3 run_genie.py --lumi 1000 --jobs 8              # 8 x 125 fb^-1 in parallel
    python3 run_genie.py --jobs 16 --run 100 --seed 4189820
    python3 run_genie.py --n-events 500                    # fixed number of events per job
    python3 run_genie.py --flux-file data/fluxes/Kling_2023/DPMJET.root --prefix faser.DPMJET
    python3 run_genie.py --tune G25_01a_00_000 --splines faser_xsec/faserSplines.7TeV_G25.xml
    python3 run_genie.py --cc-only --merge --export
    python3 run_genie.py --dry-run                         # print the plan and commands only
"""
import argparse
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent

DEFAULT_LUMI_FB = 1000.0
FLUX_PRESETS = {                # --flux NAME -> file under data/fluxes
    "light": "Aki_2024/events_light_4x4.root",
    "charm": "Aki_2024/events_charm_4x4.root",
}
# default base seeds: those of runFASERCAL_v10_Aki2024.sh, so run 0 reproduces it
DEFAULT_SEEDS = {"light": 2999833, "charm": 3999833}
DEFAULT_SEED = 2999833

# lines gevgen_faser / the status file print, parsed for the summary
STATUS_EVENT_RE = re.compile(r"Current Event Number:\s*(\d+)")
STATUS_TIME_RE = re.compile(r"Approximate total processing time:\s*([0-9.eE+-]+)")
GFASER_SAVED_RE = re.compile(r"Saving\s+(\d+)\s+events in\s+(\S+)")
NGEN_RE = re.compile(r"N of generated v interactions:\s*(\d+)")
DONE_RE = re.compile(r"\bDone!")


def tag(msg=""):
    print(f"[run_genie] {msg}", flush=True)


# ---------------------------------------------------------------------------
# locations
# ---------------------------------------------------------------------------
def genie_home() -> Path:
    """GENIE_HOME from setup.sh; falls back to this script's directory (the
    repository top), so --dry-run works even before setup.sh is sourced."""
    return Path(os.environ.get("GENIE_HOME", str(REPO_ROOT)))


def default_output_dir() -> Path:
    return Path(os.environ.get("GENIE_OUTPUT", str(genie_home() / "output")))


def faserdata_dir() -> Path:
    """The FASER simulation's data area (FASERDATA from the FASER
    repository's setup.sh), where run_convertgenie.py looks for
    GENIE/*.gfaser.root."""
    d = os.environ.get("FASERDATA")
    return Path(d) if d else None


def discover_geometry_file(gdml_dir: Path) -> Path:
    """The single *.gdml file in data/GDML -- the same rule as
    run_convertgenie.py: with none or several, stop and ask for
    --geometry-file."""
    if not gdml_dir.is_dir():
        sys.exit(f"error: GDML directory not found: {gdml_dir}\n"
                 f"       Pass --geometry-file to point at a GDML file explicitly.")
    candidates = sorted(gdml_dir.glob("*.gdml"))
    if not candidates:
        sys.exit(f"error: no .gdml file found under {gdml_dir}\n"
                 f"       Pass --geometry-file to point at one explicitly.")
    if len(candidates) > 1:
        names = ", ".join(c.name for c in candidates)
        sys.exit(f"error: multiple .gdml files found under {gdml_dir} ({names})\n"
                 f"       Pass --geometry-file to pick one explicitly.")
    return candidates[0]


def default_prefix(geometry_file: Path, flux_name: str) -> str:
    """fasercal.Aki2024.v10.light style: geometry version from the GDML
    file name (FASERCAL_V10.gdml -> v10), flux from --flux or the flux
    file name."""
    m = re.search(r"[Vv](\d+)", geometry_file.stem)
    geo = f"v{m.group(1)}" if m else geometry_file.stem.lower()
    return f"fasercal.Aki2024.{geo}.{flux_name}" if flux_name in FLUX_PRESETS \
        else f"fasercal.{geo}.{flux_name}"


def is_root_file(path: Path) -> bool:
    try:
        with open(path, "rb") as f:
            return f.read(4) == b"root"
    except OSError:
        return False


# ---------------------------------------------------------------------------
# arguments
# ---------------------------------------------------------------------------
def parse_args():
    p = argparse.ArgumentParser(
        description="Run gevgen_faser for FASER: auto-discovered inputs, parallel jobs, "
                    "run plan, progress and summary.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    g = p.add_argument_group("sample")
    g.add_argument("--flux", choices=sorted(FLUX_PRESETS), default="light",
                   help="Aki 2024 flux sample (default: light).")
    g.add_argument("--flux-file", type=Path, default=None,
                   help="Any flux file instead of --flux (gSimpleNtpFlux ntuple or histograms).")
    g.add_argument("--geometry-file", type=Path, default=None,
                   help="GDML geometry (default: the single *.gdml in $GENIE_HOME/data/GDML).")
    g.add_argument("--splines", type=Path, default=None,
                   help="Cross-section splines XML (default: $GENIE_HOME/faser_xsec/"
                        "faserSplines.7TeV.xml).")
    g.add_argument("--tune", default=None,
                   help="GENIE tune, passed as --tune (default: gevgen_faser's own default).")
    g.add_argument("--top-volume", default=None,
                   help="Passed as -t (generate only in this volume, or '+Vol1-Vol2...').")
    g.add_argument("--prefix", default=None,
                   help="Output file prefix, gevgen_faser -o (default: e.g. "
                        "fasercal.Aki2024.v10.light, from the geometry and flux).")

    g = p.add_argument_group("statistics and jobs")
    x = g.add_mutually_exclusive_group()
    x.add_argument("--lumi", type=float, default=None,
                   help=f"Total integrated luminosity in fb^-1, split evenly over the jobs "
                        f"(default: {DEFAULT_LUMI_FB:g}).")
    x.add_argument("--n-events", type=int, default=None,
                   help="Fixed number of events per job instead of a luminosity (-n).")
    g.add_argument("--jobs", type=int, default=1,
                   help="Number of jobs (default: 1). Job i has run number --run+i.")
    g.add_argument("--max-parallel", type=int, default=None,
                   help=f"Jobs running at the same time (default: number of CPUs, "
                        f"{os.cpu_count()}).")
    g.add_argument("--run", type=int, default=0,
                   help="Run number of the first job (default: 0).")
    g.add_argument("--seed", type=int, default=None,
                   help="Base random seed; the job with run number r uses seed+r (default: "
                        "2999833 for light, 3999833 for charm, as in runFASERCAL_v10_Aki2024.sh).")

    g = p.add_argument_group("output")
    g.add_argument("--output-dir", type=Path, default=None,
                   help="Where all files go (default: $GENIE_OUTPUT = $GENIE_HOME/output).")
    g.add_argument("--no-gfaser", action="store_true",
                   help="Write only the GHEP file (no --gfaser).")
    g.add_argument("--cc-only", action="store_true",
                   help="CC events only in the gFaser file (--gfaser-cc-only); GHEP keeps all.")
    g.add_argument("--merge", action="store_true",
                   help="hadd the gFaser files of all jobs into <prefix>.all.gfaser.root.")
    g.add_argument("--export", nargs="?", const="", default=None, metavar="DIR",
                   help="Copy the gFaser file(s) and the .sh record to DIR "
                        "(default DIR: $FASERDATA/GENIE) for the FASER simulation.")

    g = p.add_argument_group("control")
    g.add_argument("--dry-run", action="store_true",
                   help="Print the plan and the commands, run nothing.")
    g.add_argument("--force", "-f", action="store_true",
                   help="Overwrite existing output files without asking.")
    g.add_argument("--progress-every", type=float, default=30.0,
                   help="Seconds between progress lines (default: 30; 0 = off).")
    g.add_argument("--extra", default="",
                   help="Extra arguments appended to every gevgen_faser command, e.g. "
                        "\"--message-thresholds Messenger_laconic.xml\".")
    args = p.parse_args()

    if args.jobs < 1:
        p.error("--jobs must be >= 1")
    if args.n_events is None and args.lumi is None:
        args.lumi = DEFAULT_LUMI_FB
    if args.seed is None:
        args.seed = DEFAULT_SEEDS.get(args.flux, DEFAULT_SEED) if args.flux_file is None else DEFAULT_SEED
    if args.max_parallel is None:
        args.max_parallel = os.cpu_count() or 1
    if args.cc_only and args.no_gfaser:
        p.error("--cc-only needs the gFaser file: drop --no-gfaser")
    if args.merge and args.no_gfaser:
        p.error("--merge works on the gFaser files: drop --no-gfaser")
    return args


# ---------------------------------------------------------------------------
# inputs and commands
# ---------------------------------------------------------------------------
def resolve_inputs(args):
    home = genie_home()
    if args.geometry_file is not None:
        geometry = args.geometry_file.resolve()
    else:
        geometry = discover_geometry_file(home / "data" / "GDML").resolve()

    if args.flux_file is not None:
        flux = args.flux_file.resolve()
        flux_name = flux.stem.replace("events_", "").replace("_4x4", "")
    else:
        flux = (home / "data" / "fluxes" / FLUX_PRESETS[args.flux]).resolve()
        flux_name = args.flux

    splines = (args.splines if args.splines is not None
               else home / "faser_xsec" / "faserSplines.7TeV.xml")
    splines = splines if splines.is_absolute() else (Path.cwd() / splines)

    output_dir = (args.output_dir if args.output_dir is not None else default_output_dir()).resolve()
    prefix = args.prefix or default_prefix(geometry, flux_name)
    if "/" in prefix:
        sys.exit("error: --prefix is a file name prefix; use --output-dir for the directory")
    return geometry, flux, splines, output_dir, prefix


def check_inputs(geometry, flux, splines, dry_run):
    """Problems are fatal for a real run, warnings only for --dry-run."""
    problems = []
    if not geometry.is_file():
        problems.append(f"geometry file not found: {geometry}")
    if not flux.is_file():
        hint = "  (run: bash data/fluxes/getFluxNtp.sh)" if "Kling_2023" in str(flux) else ""
        problems.append(f"flux file not found: {flux}{hint}")
    elif not is_root_file(flux):
        problems.append(f"flux file is not a ROOT file (failed download?): {flux}")
    if not splines.exists():
        problems.append(f"splines not found: {splines}  (make them with faser/Splines, "
                        f"or copy/link them into faser_xsec/)")
    if shutil.which("gevgen_faser") is None:
        problems.append("gevgen_faser not on PATH: source setup.sh first")
    for msg in problems:
        tag(("warning: " if dry_run else "error: ") + msg)
    if problems and not dry_run:
        sys.exit(1)
    if splines.exists() and "GENIE3.04" in str(splines.resolve()):
        tag(f"warning: the splines are the 3.04 ones ({splines.resolve()}): "
            f"fine for tests, regenerate them for production")


def make_jobs(args, geometry, flux, splines, prefix):
    jobs = []
    lumi_per_job = args.lumi / args.jobs if args.lumi is not None else None
    for i in range(args.jobs):
        run = args.run + i
        seed = args.seed + run
        cmd = ["gevgen_faser"]
        if lumi_per_job is not None:
            cmd += ["-l", f"{lumi_per_job:.10g}"]
        else:
            cmd += ["-n", str(args.n_events)]
        cmd += ["-r", str(run), "-g", str(geometry), "-f", str(flux),
                "--seed", str(seed), "--cross-sections", str(splines)]
        if args.tune:
            cmd += ["--tune", args.tune]
        if args.top_volume:
            cmd += ["-t", args.top_volume]
        cmd += ["-o", prefix]
        if not args.no_gfaser:
            cmd.append("--gfaser-cc-only" if args.cc_only else "--gfaser")
        if args.extra:
            cmd += shlex.split(args.extra)
        jobs.append({"run": run, "seed": seed, "lumi": lumi_per_job, "cmd": cmd})
    return jobs


def job_files(output_dir, prefix, run, with_gfaser):
    files = {"ghep": output_dir / f"{prefix}.{run}.ghep.root",
             "status": output_dir / f"genie-mcjob-{run}.status",
             "log": output_dir / f"{prefix}.{run}.log"}
    if with_gfaser:
        files["gfaser"] = output_dir / f"{prefix}.{run}.gfaser.root"
    return files


# ---------------------------------------------------------------------------
# plan
# ---------------------------------------------------------------------------
def print_plan(args, jobs, *, geometry, flux, splines, output_dir, prefix):
    tag("==================== run plan ====================")
    tag(f"gevgen_faser:      {shutil.which('gevgen_faser') or '(not on PATH)'}")
    tag(f"geometry:          {geometry}")
    tag(f"flux:              {flux}")
    tag(f"splines:           {splines}" + (f"  -> {splines.resolve()}" if splines.is_symlink() else ""))
    tag(f"tune:              {args.tune or '(gevgen_faser default)'}")
    if args.lumi is not None:
        tag(f"luminosity:        {args.lumi:g} fb^-1 total = {args.jobs} x {args.lumi / args.jobs:g} fb^-1")
    else:
        tag(f"events:            {args.n_events} per job x {args.jobs} jobs")
    tag(f"jobs:              {args.jobs} (runs {jobs[0]['run']}..{jobs[-1]['run']}, "
        f"seeds {jobs[0]['seed']}..{jobs[-1]['seed']}), at most {min(args.max_parallel, args.jobs)} at a time")
    tag(f"output dir:        {output_dir}")
    gf = "no" if args.no_gfaser else ("yes, CC only" if args.cc_only else "yes")
    tag(f"files:             {prefix}.<run>.ghep.root" +
        ("" if args.no_gfaser else f" + {prefix}.<run>.gfaser.root") + f"  (gFaser: {gf})")
    tag(f"merge / export:    {'yes' if args.merge else 'no'} / "
        f"{'no' if args.export is None else (args.export or '$FASERDATA/GENIE')}")
    tag("==================================================")


# ---------------------------------------------------------------------------
# running
# ---------------------------------------------------------------------------
def read_status(path: Path):
    """(events so far, seconds so far) from a genie-mcjob-<run>.status file."""
    try:
        text = path.read_text(errors="replace")[:2000]
    except OSError:
        return 0, 0.0
    m_ev, m_t = STATUS_EVENT_RE.search(text), STATUS_TIME_RE.search(text)
    return (int(m_ev.group(1)) if m_ev else 0), (float(m_t.group(1)) if m_t else 0.0)


def run_jobs(jobs, *, args, output_dir, prefix):
    pending = list(jobs)
    running = {}
    t0 = time.time()
    last_progress = t0

    def stop_all(signum=None, frame=None):
        tag("interrupted: stopping the running jobs")
        for j in running.values():
            j["proc"].terminate()
        for j in running.values():
            try:
                j["proc"].wait(timeout=10)
            except subprocess.TimeoutExpired:
                j["proc"].kill()
        sys.exit(130)

    signal.signal(signal.SIGINT, stop_all)
    signal.signal(signal.SIGTERM, stop_all)

    while pending or running:
        while pending and len(running) < args.max_parallel:
            j = pending.pop(0)
            j["files"] = job_files(output_dir, prefix, j["run"], not args.no_gfaser)
            j["logf"] = open(j["files"]["log"], "w")
            j["logf"].write("# " + " ".join(shlex.quote(c) for c in j["cmd"]) + "\n")
            j["logf"].flush()
            j["start"] = time.time()
            j["proc"] = subprocess.Popen(j["cmd"], cwd=output_dir, stdout=j["logf"],
                                         stderr=subprocess.STDOUT)
            running[j["run"]] = j
            tag(f"started run {j['run']} (seed {j['seed']}), log: {j['files']['log'].name}")

        for run in list(running):
            j = running[run]
            rc = j["proc"].poll()
            if rc is not None:
                j["returncode"] = rc
                j["elapsed"] = time.time() - j["start"]
                j["logf"].close()
                del running[run]
                state = "done" if rc == 0 else f"FAILED (exit code {rc})"
                tag(f"run {run} {state} after {j['elapsed'] / 60:.1f} min")

        now = time.time()
        if args.progress_every > 0 and running and now - last_progress >= args.progress_every:
            last_progress = now
            parts = []
            for run, j in sorted(running.items()):
                ev, _ = read_status(j["files"]["status"])
                parts.append(f"r{run}:{ev}")
            done = len(jobs) - len(pending) - len(running)
            tag(f"{(now - t0) / 60:5.1f} min | finished {done}/{len(jobs)} | events so far "
                + " ".join(parts))
        time.sleep(1.0)
    return time.time() - t0


# ---------------------------------------------------------------------------
# results
# ---------------------------------------------------------------------------
def collect(job):
    """Events and timing for one finished job, from its log and status file."""
    log = job["files"]["log"].read_text(errors="replace") if job["files"]["log"].exists() else ""
    res = {"run": job["run"], "seed": job["seed"], "lumi": job["lumi"],
           "returncode": job.get("returncode"), "elapsed": job.get("elapsed", 0.0),
           "events": None, "gfaser_events": None, "done": bool(DONE_RE.search(log))}
    m = NGEN_RE.search(log)
    if m:
        res["events"] = int(m.group(1))
    else:
        ev, _ = read_status(job["files"]["status"])
        res["events"] = ev + 1 if ev else None     # status counts from 0
    m = GFASER_SAVED_RE.search(log)
    if m:
        res["gfaser_events"] = int(m.group(1))
    for k, f in job["files"].items():
        res[k] = f
    return res


def format_summary(args, results, *, geometry, flux, splines, output_dir, prefix, wall):
    w = 10
    lines = ["==================== gevgen_faser run summary ===================="]
    lines.append(f"Prefix:      {prefix}")
    lines.append(f"Output dir:  {output_dir}")
    lines.append(f"Geometry:    {geometry}")
    lines.append(f"Flux:        {flux}")
    lines.append(f"Splines:     {splines.resolve()}")
    lines.append(f"Tune:        {args.tune or '(default)'}")
    if args.lumi is not None:
        lines.append(f"Luminosity:  {args.lumi:g} fb^-1 in {len(results)} job(s) of "
                     f"{args.lumi / len(results):g} fb^-1")
    else:
        lines.append(f"Events:      {args.n_events} requested per job")
    lines.append(f"gFaser:      {'no' if args.no_gfaser else ('CC only' if args.cc_only else 'all events')}")
    header = ("run".rjust(6) + "seed".rjust(w + 2) + "events".rjust(w) +
              ("gFaser".rjust(w) if not args.no_gfaser else "") +
              "minutes".rjust(w) + "s/event".rjust(w) + "  status")
    lines += ["-" * len(header), header, "-" * len(header)]
    tot_ev = tot_gf = 0
    for r in results:
        ev = r["events"] or 0
        tot_ev += ev
        tot_gf += r["gfaser_events"] or 0
        spe = f"{r['elapsed'] / ev:.4f}" if ev else "-"
        ok = r["returncode"] == 0 and r["done"]
        row = (str(r["run"]).rjust(6) + str(r["seed"]).rjust(w + 2) +
               (str(r["events"]) if r["events"] is not None else "?").rjust(w))
        if not args.no_gfaser:
            row += (str(r["gfaser_events"]) if r["gfaser_events"] is not None else "?").rjust(w)
        row += f"{r['elapsed'] / 60:.1f}".rjust(w) + spe.rjust(w)
        row += "  ok" if ok else f"  FAILED (exit {r['returncode']}, see {r['log'].name})"
        lines.append(row)
    lines.append("-" * len(header))
    row = "TOTAL".rjust(6) + "".rjust(w + 2) + str(tot_ev).rjust(w)
    if not args.no_gfaser:
        row += str(tot_gf).rjust(w)
    lines.append(row + f"   wall time {wall / 60:.1f} min")
    if args.lumi is not None and tot_ev:
        lines.append(f"Rate:        {tot_ev / args.lumi:.2f} events per fb^-1")
    lines.append("Files:")
    for r in results:
        names = r["ghep"].name + ("" if args.no_gfaser else "  " + r["gfaser"].name)
        lines.append(f"  {names}")
    lines.append("==================================================================")
    return "\n".join(lines) + "\n"


def write_command_record(path: Path, jobs, output_dir):
    """The exact commands, as a shell script: a record of how the sample
    was made (and what run_convertgenie.py reads the luminosity from)."""
    lines = ["#!/bin/bash",
             f"# written by run_genie.py on {time.strftime('%Y-%m-%d %H:%M:%S')}",
             f"# {' '.join(shlex.quote(a) for a in sys.argv)}",
             f"cd {shlex.quote(str(output_dir))}", ""]
    for j in jobs:
        lines.append(" ".join(shlex.quote(c) for c in j["cmd"]))
    lumis = [j["lumi"] for j in jobs if j["lumi"] is not None]
    if len(jobs) > 1 and lumis:
        prefix = jobs[0]["cmd"][jobs[0]["cmd"].index("-o") + 1]
        lines += ["", f"# the merged file (--merge) holds all {len(jobs)} jobs:",
                  f"# gevgen_faser -l {sum(lumis):.10g} -o {prefix}.all"]
    path.write_text("\n".join(lines) + "\n")
    path.chmod(0o755)


def merge_gfaser(results, output_dir, prefix):
    hadd = shutil.which("hadd")
    files = [str(r["gfaser"]) for r in results if r.get("gfaser") and r["gfaser"].exists()]
    if hadd is None:
        tag("skipping --merge: hadd not on PATH (source setup.sh?)")
        return None
    if not files:
        tag("skipping --merge: no gFaser files")
        return None
    out = output_dir / f"{prefix}.all.gfaser.root"
    tag(f"merging {len(files)} gFaser file(s) into {out.name}")
    rc = subprocess.run([hadd, "-f", str(out)] + files, cwd=output_dir,
                        stdout=subprocess.DEVNULL).returncode
    if rc != 0:
        tag(f"warning: hadd exited with code {rc}")
        return None
    return out


def export_files(files, dest: Path):
    dest.mkdir(parents=True, exist_ok=True)
    for f in files:
        if f and Path(f).exists():
            shutil.copy2(f, dest / Path(f).name)
            tag(f"exported {Path(f).name} -> {dest}")


# ---------------------------------------------------------------------------
def main():
    args = parse_args()
    geometry, flux, splines, output_dir, prefix = resolve_inputs(args)
    jobs = make_jobs(args, geometry, flux, splines, prefix)

    print_plan(args, jobs, geometry=geometry, flux=flux, splines=splines,
               output_dir=output_dir, prefix=prefix)
    check_inputs(geometry, flux, splines, args.dry_run)

    if args.dry_run:
        for j in jobs:
            tag("---- " + " ".join(shlex.quote(c) for c in j["cmd"]))
        tag("--dry-run: not executing.")
        return 0

    export_dir = None
    if args.export is not None:
        export_dir = Path(args.export) if args.export else (
            faserdata_dir() / "GENIE" if faserdata_dir() else None)
        if export_dir is None:
            sys.exit("error: --export without a directory needs FASERDATA set "
                     "(source the FASER setup.sh) -- or give --export DIR")

    # existing output for these runs?
    output_dir.mkdir(parents=True, exist_ok=True)
    existing = [f for j in jobs
                for f in job_files(output_dir, prefix, j["run"], not args.no_gfaser).values()
                if f.exists()]
    if existing:
        preview = ", ".join(f.name for f in existing[:4]) + (", ..." if len(existing) > 4 else "")
        tag(f"warning: {len(existing)} output file(s) for these run numbers already exist: {preview}")
        if not args.force:
            reply = input("[run_genie] Delete them and regenerate? [y/N] ")
            if reply.strip().lower() not in ("y", "yes"):
                tag("aborted -- nothing was run (use other --run numbers, or --force).")
                return 1
        for f in existing:
            f.unlink()

    runs = f"r{jobs[0]['run']}" + (f"-{jobs[-1]['run']}" if len(jobs) > 1 else "")
    record = output_dir / f"{prefix}.{runs}.run_genie.sh"
    write_command_record(record, jobs, output_dir)
    tag(f"commands recorded in {record}")

    wall = run_jobs(jobs, args=args, output_dir=output_dir, prefix=prefix)
    results = [collect(j) for j in jobs]

    summary = format_summary(args, results, geometry=geometry, flux=flux, splines=splines,
                             output_dir=output_dir, prefix=prefix, wall=wall)
    print()
    print(summary)
    summary_path = output_dir / f"{prefix}.{runs}.run_genie_summary.log"
    summary_path.write_text(summary)
    tag(f"wrote run summary: {summary_path}")

    all_ok = all(r["returncode"] == 0 and r["done"] for r in results)
    merged = merge_gfaser(results, output_dir, prefix) if args.merge and all_ok else None
    if args.merge and not all_ok:
        tag("skipping --merge: not all jobs finished cleanly")

    if export_dir is not None:
        to_copy = [merged] if merged else [r.get("gfaser") for r in results]
        export_files(to_copy + [record, summary_path], export_dir)

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
