#!/bin/bash

cd $GENIE_OUTPUT

# this command generates 1000 events in FASER using the Kling fluxes

# gevgen_faser -n 1000 -r 0 -g $GENIE_HOME/data/obsolete/FaserNu2.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 2989819 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser

# instead of a fixed number of events, this command generates 1 fb^-1 of neutrino interactions

gevgen_faser -l 1.0 -r 0 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 2989819 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser

