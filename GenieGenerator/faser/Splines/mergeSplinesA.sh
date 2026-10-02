#!/bin/sh

mkdir -p $GENIE_HOME/faser_xsec

gspladd -d NuE_raw,NuMu_raw,NuTau_raw,AntiNuE_raw,AntiNuMu_raw,AntiNuTau_raw -o $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml