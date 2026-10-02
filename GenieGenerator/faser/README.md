Fork the FASER GenieGenerator repository to a GitLab project of your own.

Use your GitLab name in the `git clone` command.

You can name your working branch anything (`genie-working-branch` is just an example) but it should be unique

```
mkdir genie
cd genie
git clone https://:@gitlab.cern.ch:8443/[your name]/GenieGenerator.git
cd GenieGenerator
git remote add upstream https://:@gitlab.cern.ch:8443/faser/GenieGenerator.git
git fetch --tags upstream
git checkout -b genie-working-branch upstream/faser-R-3_04_00 --no-track

cd ..
# should now be in the top level genie directory
source GenieGenerator/faser/setupGenerator.sh
source GenieGenerator/faser/buildGenerator.sh  

# you are now back in the GenieGenerator directory

source faser/getXsec.sh
source faser/getFluxNtp.sh

# test by running some simple jobs

cd ../run
source ../GenieGenerator/faser/runGenerator_1.sh 
source ../GenieGenerator/faser/runGenerator_2.sh

# production scripts with SIBYLL and DPMJET

cd ../run
source ../GenieGenerator/faser/runGenerator_5_SIBYLL.sh 
source ../GenieGenerator/faser/runGenerator_5_DPMJET.sh
```

Note that the cross-section and flux Ntuple files only need to be downloaded once using getXsec.sh and getFluxNtp.sh, respectively.

To convert Genie's "ghep" root files to an ntuple readable by Athena/Calypso, do:

```
genie -q -b '$GENIE/faser/Ntuple/convertGHEP.C("input_name.ghep.root","output_name.gfaser.root")'
```
