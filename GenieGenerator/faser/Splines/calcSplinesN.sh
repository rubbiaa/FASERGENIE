#!/bin/sh

mkdir -p freeN_raw

gmkspl_faser -n 300 -p 14 -t 1000000010 -o freeN_raw/NuMu.freen.7TeV.300.xml -e 7000 >& freeN_raw/NuMu_n.7TeV.300.log &
gmkspl_faser -n 300 -p -14 -t 1000000010 -o freeN_raw/AntiNuMu.freen.7TeV.300.xml -e 7000 >& freeN_raw/AntiNuMu_n.7TeV.300.log &
gmkspl_faser -n 300 -p 12 -t 1000000010 -o freeN_raw/NuE.freen.7TeV.300.xml -e 7000 >& freeN_raw/NuE_n.7TeV.300.log &
gmkspl_faser -n 300 -p -12 -t 1000000010 -o freeN_raw/AntiNuE.freen.7TeV.300.xml -e 7000 >& freeN_raw/AntiNuE_n.7TeV.300.log &
gmkspl_faser -n 300 -p 16 -t 1000000010 -o freeN_raw/NuTau.freen.7TeV.300.xml -e 7000 >& freeN_raw/NuTau_n.7TeV.300.log &
gmkspl_faser -n 300 -p -16 -t 1000000010 -o freeN_raw/AntiNuTau.freen.7TeV.300.xml -e 7000 >& freeN_raw/AntiNuTau_n.7TeV.300.log &
gmkspl_faser -n 300 -p 14 -t 1000010010 -o freeN_raw/NuMu.freep.7TeV.300.xml -e 7000 >& freeN_raw/NuMu_p.7TeV.300.log &
gmkspl_faser -n 300 -p -14 -t 1000010010 -o freeN_raw/AntiNuMu.freep.7TeV.300.xml -e 7000 >& freeN_raw/AntiNuMu_p.7TeV.300.log &
gmkspl_faser -n 300 -p 12 -t 1000010010 -o freeN_raw/NuE.freep.7TeV.300.xml -e 7000 >& freeN_raw/NuE_p.7TeV.300.log &
gmkspl_faser -n 300 -p -12 -t 1000010010 -o freeN_raw/AntiNuE.freep.7TeV.300.xml -e 7000 >& freeN_raw/AntiNuE_p.7TeV.300.log &
gmkspl_faser -n 300 -p 16 -t 1000010010 -o freeN_raw/NuTau.freep.7TeV.300.xml -e 7000 >& freeN_raw/NuTau_p.7TeV.300.log &
gmkspl_faser -n 300 -p -16 -t 1000010010 -o freeN_raw/AntiNuTau.freep.7TeV.300.xml -e 7000 >& freeN_raw/AntiNuTau_p.7TeV.300.log &
