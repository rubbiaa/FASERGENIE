#define KlingMeta_cxx
#include "KlingMeta.h"
#include <TH2.h>
#include <TStyle.h>
#include <TCanvas.h>
#include "GSimpleNtpMeta.h"

void KlingMeta::Loop()
{
//   In a ROOT session, you can do:
//      root> .L KlingMeta.C
//      root> KlingMeta t
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
   TTree* tOut = new TTree("meta","Reformatted meta");
   tOut->SetAutoSave(0);
   genie::flux::GSimpleNtpMeta* pMeta = nullptr;
   tOut->Branch("meta", "GSimpleNtpMeta", &pMeta);

   Long64_t nentries = fChain->GetEntriesFast();

   Long64_t nbytes = 0, nb = 0;
   for (Long64_t jentry=0; jentry<nentries;jentry++) {
      Long64_t ientry = LoadTree(jentry);
      if (ientry < 0) break;
      nb = fChain->GetEntry(jentry);   nbytes += nb;
      // if (Cut(ientry) < 0) continue;
      pMeta = new genie::flux::GSimpleNtpMeta {};

      pMeta->pdglist = std::vector<Int_t> {12, -12, 14, -14, 16, -16};
      pMeta->maxEnergy = maxEnergy;
      pMeta->minWgt = minWgt;
      pMeta->maxWgt = maxWgt;
      pMeta->protons = 0.001;
      pMeta->windowBase[0] = windowBase[0];
      pMeta->windowBase[1] = windowBase[1];
      pMeta->windowBase[2] = windowBase[2];
      pMeta->windowDir1[0] = windowDir1[0];
      pMeta->windowDir1[1] = windowDir1[1];
      pMeta->windowDir1[2] = windowDir1[2];
      pMeta->windowDir2[0] = windowDir2[0];
      pMeta->windowDir2[1] = windowDir2[1];
      pMeta->windowDir2[2] = windowDir2[2];
      //      pMeta->auxintname = auxintname;
      //      pMeta->auxdblname = auxdblname;
      //      pMeta->infiles = infiles;
      pMeta->seed = seed;
      pMeta->metakey = metakey;
      tOut->Fill();
      delete pMeta;
   }
   fOut->Write();
   fOut->Close();
}
