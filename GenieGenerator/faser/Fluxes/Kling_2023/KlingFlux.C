#define KlingFlux_cxx
#include "KlingFlux.h"
#include <TH2.h>
#include <TStyle.h>
#include <TCanvas.h>
#include "GSimpleNtpEntry.h"
#include <cmath>

void KlingFlux::Loop()
{
//   In a ROOT session, you can do:
//      root> .L KlingFlux.C
//      root> KlingFlux t("infile.root", "outfile.root")
//      root> t.GetEntry(12); // Fill t data members with entry number 12
//      root> t.Show();       // Show values of entry 12
//      root> t.Show(16);     // Read and show values of entry 16
//      root> t.Loop();       // Loop on all entries
//

//     This is the loop skeleton where:
//    jentry is the global entry number in the chain
//    ientry is the entry number in the current Tree
//  Note that the argument to GetEntry must be:
//    jentry for TChain::GetEntry
//    ientry for TTree::GetEntry and TBranch::GetEntry
//
//       To read only selected branches, Insert statements like:
// METHOD1:
//    fChain->SetBranchStatus("*",0);  // disable all branches
//    fChain->SetBranchStatus("branchname",1);  // activate branchname
// METHOD2: replace line
//    fChain->GetEntry(jentry);       //read all branches
//by  b_branchname->GetEntry(ientry); //read only this branch
   if (fChain == 0) return;

   // TFile* fOut = TFile::Open("fullSampleReformat.root","UPDATE");
   fOut->cd();
   TTree* tOut = new TTree("flux","Reformatted flux");
   tOut->SetAutoSave(0);
   genie::flux::GSimpleNtpEntry* pEntry = nullptr;
   tOut->Branch("entry", "GSimpleNtpEntry", &pEntry);

   Long64_t nentries = fChain->GetEntriesFast();

   // "prime" the ntuple by reading first element before loop
   Long64_t iientry = LoadTree(0);
   Long64_t nnb = fChain->GetEntry(0);
   iientry = LoadTree(1);
   nnb = fChain->GetEntry(1);

   Long64_t nbytes = 0, nb = 0;
   for (Long64_t jentry=0; jentry<nentries;jentry++) {
      Long64_t ientry = LoadTree(jentry);
      if (ientry < 0) break;
      nb = fChain->GetEntry(jentry);   nbytes += nb;
      if (E < 10.0) 
      {
	std::cout << "Skipping invalid entry: " << jentry << std::endl;
	continue;
      }
      pEntry = new genie::flux::GSimpleNtpEntry {};
      pEntry->wgt = wgt;
      pEntry->vtxx = vtxx/1000;
      pEntry->vtxy = vtxy/1000;
      pEntry->vtxz = -5.5;
      pEntry->vtxt = -5.5/0.2998;
      pEntry->dist = dist;
      pEntry->px   = px;
      pEntry->py   = py;
      pEntry->pz   = pz;
      pEntry->E    = E;
      pEntry->pdg  = round(pdg);
      pEntry->metakey = metakey;
      tOut->Fill();
      delete pEntry;
      // if (Cut(ientry) < 0) continue;
   }
   fOut->Write();
   fOut->Close();
}
#undef KlingFlux_cxx
