#include "GSimpleNtpEntry.h"
using namespace genie::flux;

ClassImp(GSimpleNtpEntry)
//___________________________________________________________________________
GSimpleNtpEntry::GSimpleNtpEntry() {  Reset(); }

void GSimpleNtpEntry::Reset()
{
  wgt      = 0.;
  vtxx     = 0.;
  vtxy     = 0.;
  vtxz     = 0.;
  vtxt     = 0.;
  dist     = 0.;
  px       = 0.;
  py       = 0.;
  pz       = 0.;
  E        = 0.;

  pdg      =  0;
  metakey  =  0;
}

void GSimpleNtpEntry::Print(const Option_t* /* opt */ ) const
{
  std::cout << *this << std::endl;
}

    ostream & operator << (
			   ostream & stream, const genie::flux::GSimpleNtpEntry & entry)
    {
      stream << "\nGSimpleNtpEntry "
             << " PDG " << entry.pdg
             << " wgt " << entry.wgt
             << " ( metakey " << entry.metakey << " )"
             << "\n   vtx [" << entry.vtxx << "," << entry.vtxy << ","
             << entry.vtxz << ", t=" << entry.vtxt << "] dist " << entry.dist
             << "\n   p4  [" << entry.px << "," << entry.py << ","
             << entry.pz << "," << entry.E << "]";
      return stream;
    }
