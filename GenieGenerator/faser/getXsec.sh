#!/bin/bash

mkdir -p $GENIE_HOME/faser_xsec

pushd $GENIE_HOME/faser_xsec

#wget https://scisoft.fnal.gov/scisoft/packages/genie_xsec/v3_00_06/genie_xsec-3.00.06-noarch-G1802a00000-k250-e1000.tar.bz2
#tar xvf genie_xsec-3.00.06-noarch-G1802a00000-k250-e1000.tar.bz2

# wget -O faserSplines.7TeV.xml.bz2 https://cernbox.cern.ch/index.php/s/DywDPsL5A1liRW9/download

# wget -O faserSplines.7TeV.xml.bz2 https://cernbox.cern.ch/index.php/s/zbL7c4AagfaJieX/download

#
# 3.04 splines
#
wget -O faserSplines.7TeV.xml.bz2 https://cernbox.cern.ch/s/ci9TVKqVlE8RkfY/download

bzip2 -f -d faserSplines.7TeV.xml.bz2

popd
