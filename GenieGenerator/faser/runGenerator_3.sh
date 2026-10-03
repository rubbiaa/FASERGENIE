#!/bin/bash

cd $GENIE_HOME/run

# instead of a fixed number of events, each job command generates 150 fb^-1 of neutrino interactions

gevgen_faser -l 150.0 -r 1 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011301 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.1.log &
gevgen_faser -l 150.0 -r 2 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011302 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.2.log &
gevgen_faser -l 150.0 -r 3 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011303 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.3.log &
gevgen_faser -l 150.0 -r 4 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011304 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.4.log &
gevgen_faser -l 150.0 -r 5 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011305 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.5.log &
gevgen_faser -l 150.0 -r 6 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011306 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.6.log &
gevgen_faser -l 150.0 -r 7 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011307 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.7.log &
gevgen_faser -l 150.0 -r 8 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011308 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.8.log &
gevgen_faser -l 150.0 -r 9 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011309 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.9.log &
gevgen_faser -l 150.0 -r 10 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011310 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.10.log &
gevgen_faser -l 150.0 -r 11 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011311 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.11.log &
gevgen_faser -l 150.0 -r 12 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011312 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.12.log &
gevgen_faser -l 150.0 -r 13 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011313 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.13.log &
gevgen_faser -l 150.0 -r 14 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011314 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.14.log &
gevgen_faser -l 150.0 -r 15 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011315 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.15.log &
gevgen_faser -l 150.0 -r 16 -g $GENIE_HOME/data/obsolete/FaserNu3.gdml -f $GENIE_HOME/data/fluxes/Kling_2021/Kling_2021.root --seed 22011316 --cross-sections $GENIE_HOME/faser_xsec/faserSplines.7TeV.xml -o faser.150fbInv >& gevgen_faser.16.log &

