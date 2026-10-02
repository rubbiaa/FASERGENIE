/////////////////////////////////////////////////////////
// This class has been automatically generated on
// Wed Apr 19 05:24:49 2023 by ROOT version 6.24/06
// from TTree meta/
// found on file: fullsample.root
//////////////////////////////////////////////////////////

#ifndef KlingMeta_h
#define KlingMeta_h

#include <TROOT.h>
#include <TChain.h>
#include <TFile.h>

// Header file for the classes stored in the TTree if any.

class KlingMeta {
public :
   TTree          *fChain;   //!pointer to the analyzed TTree or TChain
   Int_t           fCurrent; //!current Tree number in a TChain
   TFile*          fOut;     // ROOT output file

// Fixed size dimensions of array or collections stored in the TTree if any.

   // Declaration of leaf types
   Long64_t        pdglist[6];
   Double_t        maxEnergy;
   Double_t        minWgt;
   Double_t        maxWgt;
   Double_t        protons;
   Double_t        windowBase[3];
   Double_t        windowDir1[3];
   Double_t        windowDir2[3];
   Double_t        auxintname;
   Double_t        auxdblname;
   Double_t        infiles;
   Long64_t        seed;
   Long64_t        metakey;

   // List of branches
   TBranch        *b_pdglist;   //!
   TBranch        *b_maxEnergy;   //!
   TBranch        *b_minWgt;   //!
   TBranch        *b_maxWgt;   //!
   TBranch        *b_protons;   //!
   TBranch        *b_windowBase;   //!
   TBranch        *b_windowDir1;   //!
   TBranch        *b_windowDir2;   //!
   TBranch        *b_auxintname;   //!
   TBranch        *b_auxdblname;   //!
   TBranch        *b_infiles;   //!
   TBranch        *b_seed;   //!
   TBranch        *b_metakey;   //!

   KlingMeta(const char* inFileName, const char* outFileName);
   virtual ~KlingMeta();
   virtual Int_t    Cut(Long64_t entry);
   virtual Int_t    GetEntry(Long64_t entry);
   virtual Long64_t LoadTree(Long64_t entry);
   virtual void     Init(TTree *tree);
   virtual void     Loop();
   virtual Bool_t   Notify();
   virtual void     Show(Long64_t entry = -1);
};

#endif

#ifdef KlingMeta_cxx
KlingMeta::KlingMeta(const char* inFileName, const char* outFileName) : fChain(0), fOut {nullptr} 
{
   TTree* tree {nullptr};
   TFile *f = TFile::Open(inFileName, "READONLY");
   if (!f || !f->IsOpen()) 
   {
      std::cout << "Unable to open input file named ";
      std::cout.write(inFileName, strlen(inFileName));
      std::cout << std::endl;
      return;
   }
   f->GetObject("meta",tree);

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

KlingMeta::~KlingMeta()
{
   if (fOut != nullptr) delete fOut;
   if (!fChain) return;
   delete fChain->GetCurrentFile();
}

Int_t KlingMeta::GetEntry(Long64_t entry)
{
// Read contents of entry.
   if (!fChain) return 0;
   return fChain->GetEntry(entry);
}
Long64_t KlingMeta::LoadTree(Long64_t entry)
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

void KlingMeta::Init(TTree *tree)
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

   fChain->SetBranchAddress("pdglist", pdglist, &b_pdglist);
   fChain->SetBranchAddress("maxEnergy", &maxEnergy, &b_maxEnergy);
   fChain->SetBranchAddress("minWgt", &minWgt, &b_minWgt);
   fChain->SetBranchAddress("maxWgt", &maxWgt, &b_maxWgt);
   fChain->SetBranchAddress("protons", &protons, &b_protons);
   fChain->SetBranchAddress("windowBase", windowBase, &b_windowBase);
   fChain->SetBranchAddress("windowDir1", windowDir1, &b_windowDir1);
   fChain->SetBranchAddress("windowDir2", windowDir2, &b_windowDir2);
   fChain->SetBranchAddress("auxintname", &auxintname, &b_auxintname);
   fChain->SetBranchAddress("auxdblname", &auxdblname, &b_auxdblname);
   fChain->SetBranchAddress("infiles", &infiles, &b_infiles);
   fChain->SetBranchAddress("seed", &seed, &b_seed);
   fChain->SetBranchAddress("metakey", &metakey, &b_metakey);
   Notify();
}

Bool_t KlingMeta::Notify()
{
   // The Notify() function is called when a new file is opened. This
   // can be either for a new TTree in a TChain or when when a new TTree
   // is started when using PROOF. It is normally not necessary to make changes
   // to the generated code, but the routine can be extended by the
   // user if needed. The return value is currently not used.

   return kTRUE;
}

void KlingMeta::Show(Long64_t entry)
{
// Print contents of entry.
// If entry is not specified, print current entry
   if (!fChain) return;
   fChain->Show(entry);
}
Int_t KlingMeta::Cut(Long64_t entry)
{
// This function may be called from Loop.
// returns  1 if entry is accepted.
// returns -1 otherwise.
   return 1;
}
#endif // #ifdef KlingMeta_cxx
