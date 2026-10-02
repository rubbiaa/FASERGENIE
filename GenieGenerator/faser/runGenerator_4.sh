#!/bin/bash

cd $GENIE_HOME/run

# instead of a fixed number of events, each job command generates 10 fb^-1 of neutrino interactions

gevgen_faser -l 10.0 -r 1 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052001 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.1.log &
gevgen_faser -l 10.0 -r 2 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052002 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.2.log &
gevgen_faser -l 10.0 -r 3 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052003 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.3.log &
gevgen_faser -l 10.0 -r 4 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052004 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.4.log &
gevgen_faser -l 10.0 -r 5 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052005 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.5.log &
gevgen_faser -l 10.0 -r 6 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052006 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.6.log &
gevgen_faser -l 10.0 -r 7 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052007 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.7.log &
gevgen_faser -l 10.0 -r 8 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052008 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.8.log &
gevgen_faser -l 10.0 -r 9 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052009 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.9.log &
gevgen_faser -l 10.0 -r 10 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052010 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.10.log &
gevgen_faser -l 10.0 -r 11 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052011 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.11.log &
gevgen_faser -l 10.0 -r 12 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052012 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.12.log &
gevgen_faser -l 10.0 -r 13 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052013 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.13.log &
gevgen_faser -l 10.0 -r 14 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052014 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.14.log &
gevgen_faser -l 10.0 -r 15 -g $GENIE/faser/Geometry/FaserNu3.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052015 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.15.log &
#gevgen_faser -l 10.0 -r 16 -g $GENIE/faser/Geometry/FaserNu2.gdml -f $GENIE/faser/Fluxes/Kling_2021/Kling_2021.root --seed 22052016 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser3.10fbInv >& gevgen_faser3.16.log &

