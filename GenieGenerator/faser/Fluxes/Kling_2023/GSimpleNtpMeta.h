#pragma once
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <iostream>
#include <vector>

namespace genie {
  namespace flux {
    class GSimpleNtpMeta;
    ostream & operator << (ostream & stream, const GSimpleNtpMeta & info);

/// GSimpleNtpMeta
/// =========================
/// A small persistable C-struct -like class that holds metadata
/// about the the SimpleNtpFlux ntple.
///
class GSimpleNtpMeta: public TObject {
 public:
  GSimpleNtpMeta();
  /* allow default copy constructor ... for now nothing special
       GSimpleNtpMeta(const GSimpleNtpMeta & info);
  */
  virtual ~GSimpleNtpMeta();

  void Reset();
  void AddFlavor(Int_t nupdg);
  void Print(const Option_t* opt = "") const;
  friend ostream & operator << (ostream & stream, const GSimpleNtpMeta & info);

  std::vector<Int_t>  pdglist; ///< list of neutrino flavors

  Double_t maxEnergy;   ///< maximum energy
  Double_t minWgt;      ///< minimum weight
  Double_t maxWgt;      ///< maximum weight
  Double_t protons;     ///< represented number of protons-on-target

  Double_t windowBase[3]; ///< x,y,z position of window base point
  Double_t windowDir1[3]; ///< dx,dy,dz of window direction 1
  Double_t windowDir2[3]; ///< dx,dy,dz of window direction 2

  std::vector<std::string>    auxintname;  ///< tagname of aux ints associated w/ entry
  std::vector<std::string>    auxdblname;  ///< tagname of aux doubles associated w/ entry
  std::vector<std::string>    infiles; ///< list of input files

  Int_t    seed;     ///< random seed used in generation
  UInt_t   metakey;  ///< index key to tie to individual entries

  static UInt_t mxfileprint;  ///< allow user to limit # of files to print

  ClassDef(GSimpleNtpMeta,1)
    };
  }
}
