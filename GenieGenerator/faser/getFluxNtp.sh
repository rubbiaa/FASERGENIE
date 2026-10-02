#!/bin/bash

mkdir -p $GENIE/faser/Fluxes/Kling_2023

pushd $GENIE/faser/Fluxes/Kling_2023

#DPMJET high statistics, all flavors
wget -O DPMJET.root https://cernbox.cern.ch/s/4OT9Dua4t0UsZjP/download

#SIBYLL high statistics, all flavors
wget -O SIBYLL.root https://cernbox.cern.ch/s/yIrvMRThzSmvXnN/download

#SIBYLL light quarks
wget -O light_SIBYLL.root https://cernbox.cern.ch/s/XnMmBaN2VAn2dXb/download

#EPOSLHC light quarks
wget -O light_EPOSLHC.root https://cernbox.cern.ch/s/CbCduUoD12fM6YF/download

#QGSJET light quarks
wget -O light_QGSJET.root https://cernbox.cern.ch/s/he62AWnJxYE7fwk/download

#SIBYLL charm quarks
wget -O charm_SIBYLL.root https://cernbox.cern.ch/s/HSqzCuRXdsHNDNH/download

#NLO charm quarks
wget -O charm_NLO.root https://cernbox.cern.ch/s/RYVtKgMDCBzWWkR/download

#DPMJET charm quarks
wget -O charm_DPMJET.root https://cernbox.cern.ch/s/GEcRMnsPALlIZXp/download

popd
