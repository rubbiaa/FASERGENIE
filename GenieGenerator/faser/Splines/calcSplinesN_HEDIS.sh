#!/bin/sh

mkdir -p freeN_raw_HEDIS

gmkspl_faser -n 300 -p 14 -t 1000000010 -o freeN_raw_HEDIS/NuMu.freen.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/NuMu_n.7TeV.300.log &
gmkspl_faser -n 300 -p -14 -t 1000000010 -o freeN_raw_HEDIS/AntiNuMu.freen.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/AntiNuMu_n.7TeV.300.log &
gmkspl_faser -n 300 -p 12 -t 1000000010 -o freeN_raw_HEDIS/NuE.freen.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/NuE_n.7TeV.300.log &
gmkspl_faser -n 300 -p -12 -t 1000000010 -o freeN_raw_HEDIS/AntiNuE.freen.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/AntiNuE_n.7TeV.300.log &
gmkspl_faser -n 300 -p 16 -t 1000000010 -o freeN_raw_HEDIS/NuTau.freen.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/NuTau_n.7TeV.300.log &
gmkspl_faser -n 300 -p -16 -t 1000000010 -o freeN_raw_HEDIS/AntiNuTau.freen.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/AntiNuTau_n.7TeV.300.log &
gmkspl_faser -n 300 -p 14 -t 1000010010 -o freeN_raw_HEDIS/NuMu.freep.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/NuMu_p.7TeV.300.log &
gmkspl_faser -n 300 -p -14 -t 1000010010 -o freeN_raw_HEDIS/AntiNuMu.freep.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/AntiNuMu_p.7TeV.300.log &
gmkspl_faser -n 300 -p 12 -t 1000010010 -o freeN_raw_HEDIS/NuE.freep.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/NuE_p.7TeV.300.log &
gmkspl_faser -n 300 -p -12 -t 1000010010 -o freeN_raw_HEDIS/AntiNuE.freep.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/AntiNuE_p.7TeV.300.log &
gmkspl_faser -n 300 -p 16 -t 1000010010 -o freeN_raw_HEDIS/NuTau.freep.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/NuTau_p.7TeV.300.log &
gmkspl_faser -n 300 -p -16 -t 1000010010 -o freeN_raw_HEDIS/AntiNuTau.freep.7TeV.300.xml -e 7000 --tune GHE19_00a_00_000 >& freeN_raw_HEDIS/AntiNuTau_p.7TeV.300.log &
