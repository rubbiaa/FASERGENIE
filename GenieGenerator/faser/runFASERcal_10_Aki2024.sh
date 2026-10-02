#!/bin/bash

cd $GENIE_HOME/run

# this command generates 1000 events in FASER using the Aki 2024 fluxes https://twiki.cern.ch/twiki/bin/view/FASER/Run420benchmark
# instead of a fixed number of events, this command generates 1000 fb^-1 of neutrino interactions ten times

gevgen_faser -l 1000.0 -r 0 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999830 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 0 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999830 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 1 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999831 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 1 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999831 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 2 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999832 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 2 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999832 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 3 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999833 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 3 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999833 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 4 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999834 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 4 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999834 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 5 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999835 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 5 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999835 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 6 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999836 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 6 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999836 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 7 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999837 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 7 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999837 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 8 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999838 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 8 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999838 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm

gevgen_faser -l 1000.0 -r 9 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_light_4x4.root --seed 2999839 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.light

gevgen_faser -l 1000.0 -r 9 -g $GENIE/faser/geometry_v6.gdml -f $GENIE/faser/Fluxes/Aki_2024/events_charm_4x4.root --seed 3999839 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o fasercal.Aki2024.charm


