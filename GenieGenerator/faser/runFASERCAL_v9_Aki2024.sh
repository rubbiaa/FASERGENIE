#!/bin/bash

cd $GENIE_HOME/run

# this command generates events in FASER using the Aki 2024 fluxes https://twiki.cern.ch/twiki/bin/view/FASER/Run420benchmark
# instead of a fixed number of events, this command generates 1000 fb^-1 of neutrino interactions ten times

gevgen_faser -l 1000.0 -r 0 -g $GENIE/faser/FASERCAL_V9.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999833 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.W5.light

gevgen_faser -l 1000.0 -r 0 -g $GENIE/faser/FASERCAL_V9.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999833 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.W5.charm


