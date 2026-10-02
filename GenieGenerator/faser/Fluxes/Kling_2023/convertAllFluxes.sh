#!/bin/sh

root -b -l -q GSimpleNtpEntry.C+ GSimpleNtpMeta.C+

root -b -l -q 'convertFlux.C("raw_DPMJET.root","DPMJET.root")'
root -b -l -q 'convertFlux.C("raw_SIBYLL.root","SIBYLL.root")'
root -b -l -q 'convertFlux.C("raw_light_EPOSLHC.root","light_EPOSLHC.root")'
root -b -l -q 'convertFlux.C("raw_light_QGSJET.root","light_QGSJET.root")'
root -b -l -q 'convertFlux.C("raw_light_SIBYLL.root","light_SIBYLL.root")'
root -b -l -q 'convertFlux.C("raw_charm_DPMJET.root","charm_DPMJET.root")'
root -b -l -q 'convertFlux.C("raw_charm_NLO.root","charm_NLO.root")'
root -b -l -q 'convertFlux.C("raw_charm_SIBYLL.root","charm_SIBYLL.root")'
