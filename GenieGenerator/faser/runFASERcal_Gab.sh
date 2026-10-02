#!/bin/bash

cd $GENIE_HOME/run

# this command generates 1000 events in FASER using the Aki 2024 fluxes https://twiki.cern.ch/twiki/bin/view/FASER/Run420benchmark
# instead of a fixed number of events, this command generates 1000 fb^-1 of neutrino interactions ten times

gevgen_faser -l 1000.0 -r 0 -g $GENIE/faser/geometry_v5.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2989820 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV_G25.xml --tune G25_01a_00_000 -o fasercal.Gab1.light




