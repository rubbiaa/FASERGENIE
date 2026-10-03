// dump_gfaser.C -- write the gFaser tree of a .gfaser.root file as plain text,
// one line per event, for run_regression.py (which needs no PyROOT this way).
//
//   root -l -b -q 'dump_gfaser.C("in.gfaser.root","out.txt")'
//
// Line format:  vx vy vz n | pdg st fm lm fd ld px py pz E m ; pdg st ... ;
// A first line "#weight <w> entries <n>" carries the tree weight (POT/lumi
// normalization, 0 when not set) and the number of entries.
#include <TFile.h>
#include <TTree.h>
#include <cstdio>
#include <vector>
#include <string>

int dump_gfaser(const char* in, const char* out, long maxEvents = -1)
{
  TFile* f = TFile::Open(in, "READ");
  if (!f || f->IsZombie()) { fprintf(stderr, "dump_gfaser: cannot open %s\n", in); return 1; }
  TTree* t = (TTree*) f->Get("gFaser");
  if (!t) { fprintf(stderr, "dump_gfaser: no gFaser tree in %s\n", in); return 1; }

  double vx = 0, vy = 0, vz = 0; int n = 0;
  std::vector<int> *pdgc = nullptr, *status = nullptr, *fm = nullptr, *lm = nullptr,
                   *fd = nullptr, *ld = nullptr;
  std::vector<double> *px = nullptr, *py = nullptr, *pz = nullptr, *E = nullptr, *m = nullptr;
  t->SetBranchAddress("vx", &vx); t->SetBranchAddress("vy", &vy); t->SetBranchAddress("vz", &vz);
  t->SetBranchAddress("n", &n);
  t->SetBranchAddress("pdgc", &pdgc); t->SetBranchAddress("status", &status);
  t->SetBranchAddress("firstMother", &fm); t->SetBranchAddress("lastMother", &lm);
  t->SetBranchAddress("firstDaughter", &fd); t->SetBranchAddress("lastDaughter", &ld);
  t->SetBranchAddress("px", &px); t->SetBranchAddress("py", &py); t->SetBranchAddress("pz", &pz);
  t->SetBranchAddress("E", &E); t->SetBranchAddress("m", &m);
  t->SetBranchStatus("name", 0);
  t->SetBranchStatus("M", 0);

  FILE* o = fopen(out, "w");
  if (!o) { fprintf(stderr, "dump_gfaser: cannot write %s\n", out); return 1; }
  long nent = t->GetEntries();
  if (maxEvents >= 0 && maxEvents < nent) nent = maxEvents;
  fprintf(o, "#weight %.10g entries %ld\n", t->GetWeight(), nent);
  for (long i = 0; i < nent; i++) {
    t->GetEntry(i);
    fprintf(o, "%.9g %.9g %.9g %d |", vx, vy, vz, n);
    for (size_t k = 0; k < pdgc->size(); k++)
      fprintf(o, " %d %d %d %d %d %d %.9g %.9g %.9g %.9g %.9g ;", (*pdgc)[k], (*status)[k],
              (*fm)[k], (*lm)[k], (*fd)[k], (*ld)[k], (*px)[k], (*py)[k], (*pz)[k], (*E)[k], (*m)[k]);
    fprintf(o, "\n");
  }
  fclose(o);
  f->Close();
  return 0;
}
