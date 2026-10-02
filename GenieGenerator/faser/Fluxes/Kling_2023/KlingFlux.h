//////////////////////////////////////////////////////////
// This class has been automatically generated on
// Wed Apr 19 05:24:33 2023 by ROOT version 6.24/06
// from TTree flux/
// found on file: fullsample.root
//////////////////////////////////////////////////////////

#ifndef KlingFlux_h
#define KlingFlux_h

#include <TROOT.h>
#include <TChain.h>
#include <TFile.h>

// Header file for the classes stored in the TTree if any.

class KlingFlux {
public :
   TTree          *fChain;   //!pointer to the analyzed TTree or TChain
   Int_t           fCurrent; //!current Tree number in a TChain
   TFile*          fOut;     // ROOT file for the translated data

// Fixed size dimensions of array or collections stored in the TTree if any.

   // Declaration of leaf types
   Double_t        wgt;
   Double_t        vtxx;
   Double_t        vtxy;
   Double_t        vtxz;
   Double_t        metakey;
   Double_t        dist;
   Double_t        px;
   Double_t        py;
   Double_t        pz;
   Double_t        E;
   Double_t        pdg;

   // List of branches
   TBranch        *b_wgt;   //!
   TBranch        *b_vtxx;   //!
   TBranch        *b_vtxy;   //!
   TBranch        *b_vtxz;   //!
   TBranch        *b_metakey;   //!
   TBranch        *b_dist;   //!
   TBranch        *b_px;   //!
   TBranch        *b_py;   //!
   TBranch        *b_pz;   //!
   TBranch        *b_E;   //!
   TBranch        *b_pdg;   //!

   KlingFlux(const char* inFileName, const char* outFileName);
   virtual ~KlingFlux();
   virtual Int_t    Cut(Long64_t entry);
   virtual Int_t    GetEntry(Long64_t entry);
   virtual Long64_t LoadTree(Long64_t entry);
   virtual void     Init(TTree *tree);
   virtual void     Loop();
   virtual Bool_t   Notify();
   virtual void     Show(Long64_t entry = -1);
};

#endif

#ifdef KlingFlux_cxx
KlingFlux::KlingFlux(const char* inFileName, const char* outFileName) : fChain(0), fOut {nullptr}
{
// if parameter tree is not specified (or zero), connect the file
// used to generate this class and read the Tree.
   TTree* tree {nullptr};
   TFile *f = TFile::Open(inFileName, "READONLY");
   if (!f || !f->IsOpen()) 
   {
      std::cout << "Unable to open input file named ";
      std::cout.write(inFileName, strlen(inFileName));
      std::cout << std::endl;
      return;
   }
   f->GetObject("flux",tree);

   Init(tree);

   fOut = TFile::Open(outFileName,"UPDATE");
   if (!fOut || !fOut->IsOpen())
   {
      std::cout << "Unable to open output file named ";
      std::cout.write(outFileName, strlen(outFileName));
      std::cout << std::endl;
      f->Close();
      return;
   }
}

KlingFlux::~KlingFlux()
{
   if (fOut != nullptr) delete fOut;
   if (!fChain) return;
   delete fChain->GetCurrentFile();
}

Int_t KlingFlux::GetEntry(Long64_t entry)
{
// Read contents of entry.
   if (!fChain) return 0;
   return fChain->GetEntry(entry);
}
Long64_t KlingFlux::LoadTree(Long64_t entry)
{
// Set the environment to read one entry
   if (!fChain) return -5;
   Long64_t centry = fChain->LoadTree(entry);
   if (centry < 0) return centry;
   if (fChain->GetTreeNumber() != fCurrent) {
      fCurrent = fChain->GetTreeNumber();
      Notify();
   }
   return centry;
}

void KlingFlux::Init(TTree *tree)
{
   // The Init() function is called when the selector needs to initialize
   // a new tree or chain. Typically here the branch addresses and branch
   // pointers of the tree will be set.
   // It is normally not necessary to make changes to the generated
   // code, but the routine can be extended by the user if needed.
   // Init() will be called many times when running on PROOF
   // (once per file to be processed).

   // Set branch addresses and branch pointers
   if (!tree) return;
   fChain = tree;
   fCurrent = -1;
   fChain->SetMakeClass(1);

   fChain->SetBranchAddress("wgt", &wgt, &b_wgt);
   fChain->SetBranchAddress("vtxx", &vtxx, &b_vtxx);
   fChain->SetBranchAddress("vtxy", &vtxy, &b_vtxy);
   fChain->SetBranchAddress("vtxz", &vtxz, &b_vtxz);
   fChain->SetBranchAddress("metakey", &metakey, &b_metakey);
   fChain->SetBranchAddress("dist", &dist, &b_dist);
   fChain->SetBranchAddress("px", &px, &b_px);
   fChain->SetBranchAddress("py", &py, &b_py);
   fChain->SetBranchAddress("pz", &pz, &b_pz);
   fChain->SetBranchAddress("E", &E, &b_E);
   fChain->SetBranchAddress("pdg", &pdg, &b_pdg);
   Notify();
}

Bool_t KlingFlux::Notify()
{
   // The Notify() function is called when a new file is opened. This
   // can be either for a new TTree in a TChain or when when a new TTree
   // is started when using PROOF. It is normally not necessary to make changes
   // to the generated code, but the routine can be extended by the
   // user if needed. The return value is currently not used.

   return kTRUE;
}

void KlingFlux::Show(Long64_t entry)
{
// Print contents of entry.
// If entry is not specified, print current entry
   if (!fChain) return;
   fChain->Show(entry);
}
Int_t KlingFlux::Cut(Long64_t entry)
{
// This function may be called from Loop.
// returns  1 if entry is accepted.
// returns -1 otherwise.
   return 1;
}
#endif // #ifdef KlingFlux_cxx
