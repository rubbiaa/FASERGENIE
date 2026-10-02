This folder is where the faser/getFluxNtp.sh script will copy flux Ntuples derived from Felix Kling's calculations.

The raw ntuples provided by Felix must be converted to a format Genie can use.  Neither PYROOT nor uproot can
create a TTree filled with arbitrary C++ objects, which Genie expects.  So the python-generated root files
from Felix must be processed through the C++ ROOT application and put into the required format.

The scripts in this folder do that, but should generally not be run by the user.  The getFluxNtp.sh script will
copy already-converted ROOT files from CERNBOX.  These files will be generated and uploaded by the maintainer(s).

```
# should be in the top level genie directory
fsetup Athena,22.0.49
cd GenieGenerator/faser/Fluxes/Kling_2023

# create ROOT dictionary libraries for Genie classes (only needs to be done once)
root -b -l -q GSimpleNtpEntry.C+ GSimpleNtpMeta.C+

# convert raw Kling file to Genie-compatible (change the file names to reflect the actual sample)
root -b -l -q 'convertFlux.C("rawFile.root","convertedFile.root")'
```

All known ntuples (as of August 2023) can be converted with:

```
fsetup Athena,22.0.49
cd GenieGenerator/faser/Fluxes/Kling_2023

source convertAllFluxes.sh
```

This assumes the files are named as in the script, and in the Kling_2023 directory.
