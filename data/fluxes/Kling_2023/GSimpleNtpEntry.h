#pragma once
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <iostream>

namespace genie {
  namespace flux  {


  class GSimpleNtpEntry;
  ostream & operator << (ostream & stream, const GSimpleNtpEntry & info);

/// Small persistable C-struct -like classes that makes up the SimpleNtpFlux
/// ntuple.  This is only valid for a particular flux window (no reweighting,
/// no coordinate transformation available).
///
/// Order elements from largest to smallest for ROOT alignment purposes

/// GSimpleNtpEntry
/// =========================
/// This is the only required branch ("entry") of the "flux" tree
class GSimpleNtpEntry {
 public:
  GSimpleNtpEntry();
  /* allow default copy constructor ... for now nothing special
       GSimpleNtpEntry(const GSimpleNtpEntry & info);
  */
  virtual ~GSimpleNtpEntry() { };
  void Reset();
  void Print(const Option_t* opt = "") const;
  friend ostream & operator << (ostream & stream, const GSimpleNtpEntry & info);

  Double_t   wgt;      ///< nu weight

  Double_t   vtxx;     ///< x position in lab frame (meters)
  Double_t   vtxy;     ///< y position in lab frame
  Double_t   vtxz;     ///< z position in lab frame
  Double_t   vtxt;     ///< time of ray start (seconds)
  Double_t   dist;     ///< distance from hadron decay

  Double_t   px;       ///< x momentum in lab frame (GeV)
  Double_t   py;       ///< y momentum in lab frame
  Double_t   pz;       ///< z momentum in lab frame
  Double_t   E;        ///< energy in lab frame

  Int_t      pdg;      ///< nu pdg-code
  UInt_t     metakey;  ///< key to meta data

  ClassDef(GSimpleNtpEntry,2)
    };
  }
}
