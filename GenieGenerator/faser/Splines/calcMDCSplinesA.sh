#!/bin/sh

mkdir -p AntiNuE_mdc

gmkspl_faser -n 300 -p -12  -t 1000190390,1000190400,1000190410,1000200400,1000200420 --input-cross-sections ./N.7TeV.300.xml -o AntiNuE_mdc/AntiNuE.17.7TeV.300.xml -e 7000 >& AntiNuE_mdc/AntiNuE.17.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000200430,1000200440,1000200460,1000200480 --input-cross-sections ./N.7TeV.300.xml -o AntiNuE_mdc/AntiNuE.18.7TeV.300.xml -e 7000 >& AntiNuE_mdc/AntiNuE.18.7TeV.log &

mkdir -p AntiNuMu_mdc

gmkspl_faser -n 300 -p -14  -t 1000190390,1000190400,1000190410,1000200400,1000200420 --input-cross-sections ./N.7TeV.300.xml -o AntiNuMu_mdc/AntiNuMu.17.7TeV.300.xml -e 7000 >& AntiNuMu_mdc/AntiNuMu.17.7TeV.log &
gmkspl_faser -n 300 -p -14  -t 1000200430,1000200440,1000200460,1000200480 --input-cross-sections ./N.7TeV.300.xml -o AntiNuMu_mdc/AntiNuMu.18.7TeV.300.xml -e 7000 >& AntiNuMu_mdc/AntiNuMu.18.7TeV.log &

mkdir -p AntiNuTau_mdc

gmkspl_faser -n 300 -p -16  -t 1000190390,1000190400,1000190410,1000200400,1000200420 --input-cross-sections ./N.7TeV.300.xml -o AntiNuTau_mdc/AntiNuTau.17.7TeV.300.xml -e 7000 >& AntiNuTau_mdc/AntiNuTau.17.7TeV.log &
gmkspl_faser -n 300 -p -16  -t 1000200430,1000200440,1000200460,1000200480 --input-cross-sections ./N.7TeV.300.xml -o AntiNuTau_mdc/AntiNuTau.18.7TeV.300.xml -e 7000 >& AntiNuTau_mdc/AntiNuTau.18.7TeV.log &

mkdir -p NuE_mdc

gmkspl_faser -n 300 -p 12  -t 1000190390,1000190400,1000190410,1000200400,1000200420 --input-cross-sections ./N.7TeV.300.xml -o NuE_mdc/NuE.17.7TeV.300.xml -e 7000 >& NuE_mdc/NuE.17.7TeV.log &
gmkspl_faser -n 300 -p 12  -t 1000200430,1000200440,1000200460,1000200480 --input-cross-sections ./N.7TeV.300.xml -o NuE_mdc/NuE.18.7TeV.300.xml -e 7000 >& NuE_mdc/NuE.18.7TeV.log &

mkdir -p NuMu_mdc

gmkspl_faser -n 300 -p 14  -t 1000190390,1000190400,1000190410,1000200400,1000200420 --input-cross-sections ./N.7TeV.300.xml -o NuMu_mdc/NuMu.17.7TeV.300.xml -e 7000 >& NuMu_mdc/NuMu.17.7TeV.log &
gmkspl_faser -n 300 -p 14  -t 1000200430,1000200440,1000200460,1000200480 --input-cross-sections ./N.7TeV.300.xml -o NuMu_mdc/NuMu.18.7TeV.300.xml -e 7000 >& NuMu_mdc/NuMu.18.7TeV.log &

mkdir -p NuTau_mdc

gmkspl_faser -n 300 -p 16  -t 1000190390,1000190400,1000190410,1000200400,1000200420 --input-cross-sections ./N.7TeV.300.xml -o NuTau_mdc/NuTau.17.7TeV.300.xml -e 7000 >& NuTau_mdc/NuTau.17.7TeV.log &
gmkspl_faser -n 300 -p 16  -t 1000200430,1000200440,1000200460,1000200480 --input-cross-sections ./N.7TeV.300.xml -o NuTau_mdc/NuTau.18.7TeV.300.xml -e 7000 >& NuTau_mdc/NuTau.18.7TeV.log &