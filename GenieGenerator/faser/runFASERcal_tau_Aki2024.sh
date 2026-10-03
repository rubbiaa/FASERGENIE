#!/bin/bash

cd $GENIE_HOME/run

# this command generates events in FASER using the Aki 2024 fluxes https://twiki.cern.ch/twiki/bin/view/FASER/Run420benchmark
# instead of a fixed number of events, this command generates 1000 fb^-1 of neutrino interactions ten times

#  gevgen_faser -l 100000.0 -r 0 -g $GENIE_HOME/data/obsolete/geometry_v6_W1.gdml -f $GENIE_HOME/data/fluxes/Aki_2024/events_light_4x4.root --seed 2999833 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.W1.light

gevgen_faser -l 2000000.0 -r 0 -g $GENIE_HOME/data/obsolete/geometry_v6_W1.gdml -f $GENIE_HOME/data/fluxes/Aki_2024/events_charm_4x4.root --seed 3999834 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.W1.charm


