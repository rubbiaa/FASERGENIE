#include "GSimpleNtpMeta.h"
#include <TMath.h>
#include <limits.h>

using namespace genie::flux;

ClassImp(GSimpleNtpMeta)

UInt_t genie::flux::GSimpleNtpMeta::mxfileprint = UINT_MAX;

//___________________________________________________________________________
GSimpleNtpMeta::GSimpleNtpMeta()
: TObject() //, nflavors(0), flavor(0)
{
  Reset();
}

GSimpleNtpMeta::~GSimpleNtpMeta()
{
  Reset();
}

void GSimpleNtpMeta::Reset()
{

  pdglist.clear();
  maxEnergy    = 0.;
  minWgt       = 0.;
  maxWgt       = 0.;
  protons      = 0.;
  windowBase[0]  = 0.;
  windowBase[1]  = 0.;
  windowBase[2]  = 0.;
  windowDir1[0]  = 0.;
  windowDir1[1]  = 0.;
  windowDir1[2]  = 0.;
  windowDir2[0]  = 0.;
  windowDir2[1]  = 0.;
  windowDir2[2]  = 0.;

  auxintname.clear();
  auxdblname.clear();
  infiles.clear();

  seed     = 0;
  metakey  = 0;
}

void GSimpleNtpMeta::AddFlavor(Int_t nupdg)
{
  bool found = false;
  for (size_t i=0; i < pdglist.size(); ++i)
    if ( pdglist[i] == nupdg) found = true;
  if ( ! found ) pdglist.push_back(nupdg);

  /* // OLD fashion array
  bool found = false;
  for (int i=0; i < nflavors; ++i) if ( flavor[i] == nupdg ) found = true;
  if ( ! found ) {
    Int_t* old_list = flavor;
    flavor = new Int_t[nflavors+1];
    for (int i=0; i < nflavors; ++i) flavor[i] = old_list[i];
    flavor[nflavors] = nupdg;
    nflavors++;
    delete [] old_list;
  }
  */
}

void GSimpleNtpMeta::Print(const Option_t* /* opt */ ) const
{
  std::cout << *this << std::endl;
}

ostream & operator << (
		       ostream & stream, const genie::flux::GSimpleNtpMeta & meta)
{
  size_t nf = meta.pdglist.size();
  stream << "\nGSimpleNtpMeta " << nf << " flavors: ";
  for (size_t i=0; i<nf; ++i) stream << " " << meta.pdglist[i];

  //stream << "\nGSimpleNtpMeta " << meta.nflavors
  //       << " flavors: ";
  //for (int i=0; i< meta.nflavors; ++i) stream << " " << meta.flavor[i];

  stream << "\n maxEnergy " << meta.maxEnergy
	 << " min/maxWgt " << meta.minWgt << "/" << meta.maxWgt
	 << " protons " << meta.protons
	 << " metakey " << meta.metakey
	 << "\n windowBase [" << meta.windowBase[0] << ","
	 << meta.windowBase[1] << "," << meta.windowBase[2] << "]"
	 << "\n windowDir1 [" << meta.windowDir1[0] << ","
	 << meta.windowDir1[1] << "," << meta.windowDir1[2] << "]"
	 << "\n windowDir2 [" << meta.windowDir2[0] << ","
	 << meta.windowDir2[1] << "," << meta.windowDir2[2] << "]";

  size_t nInt = meta.auxintname.size();
  if ( nInt > 0 ) stream << "\n aux ints:    ";
  for (size_t ijInt=0; ijInt < nInt; ++ijInt)
    stream << " " << meta.auxintname[ijInt];

  size_t nDbl = meta.auxdblname.size();
  if ( nDbl > 0 ) stream << "\n aux doubles: ";
  for (size_t ijDbl=0; ijDbl < nDbl; ++ijDbl)
    stream << " " << meta.auxdblname[ijDbl];

  size_t nfiles = meta.infiles.size();
  stream << "\n " << nfiles << " input files: ";
  UInt_t nprint = TMath::Min(UInt_t(nfiles),
			     genie::flux::GSimpleNtpMeta::mxfileprint);
  for (UInt_t ifiles=0; ifiles < nprint; ++ifiles)
    stream << "\n    " << meta.infiles[ifiles];

  stream << "\n input seed: " << meta.seed;

  return stream;
}
