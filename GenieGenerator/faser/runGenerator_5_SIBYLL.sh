#!/bin/bash

cd $GENIE_HOME/run

# instead of a fixed number of events, each job command generates 600 fb^-1 of neutrino interactions

#gevgen_faser -l 600.0 -r 1 -g $GENIE_HOME/data/obsolete/FaserNu4.gdml -f $GENIE_HOME/data/fluxes/Kling_2023/DPMJET.root --seed 23092501 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser4.600fbInv.DPMJET
gevgen_faser -l 600.0 -r 1 -g $GENIE_HOME/data/obsolete/FaserNu4.gdml -f $GENIE_HOME/data/fluxes/Kling_2023/SIBYLL.root --seed 23092502 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser4.600fbInv.SIBYLL

