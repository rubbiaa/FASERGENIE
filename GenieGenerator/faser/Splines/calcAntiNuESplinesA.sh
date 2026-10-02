#!/bin/sh

mkdir -p AntiNuE_raw

gmkspl_faser -n 300 -p -12  -t 1000010020,1000040090,1000050100,1000050110,1000060120,1000060130 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.1.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.1.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000070140,1000070150,1000080160,1000080170,1000080180,1000110230 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.2.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.2.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000120240,1000120250,1000120260,1000130270,1000140280,1000140290 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.3.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.3.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000140300,1000160320,1000160330,1000160340,1000160360,1000170350 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.4.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.4.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000170370,1000180360,1000180380,1000180400,1000220460,1000220470 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.5.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.5.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000220480,1000220490,1000220500,1000240500,1000240520,1000240530 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.6.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.6.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000240540,1000250550,1000260540,1000260560,1000260570,1000260580 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.7.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.7.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000280580,1000280590,1000280600,1000280610,1000280620,1000280640 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.8.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.8.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000290630,1000290640,1000290650,1000300640,1000300650,1000300660 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.9.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.9.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000300670,1000300680,1000300700,1000350790,1000350800,1000350810 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.10.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.10.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000471070,1000471080,1000471090,1000501120,1000501140,1000501150 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.11.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.11.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000501160,1000501170,1000501180,1000501190,1000501200 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.12.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.12.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000501220,1000501240,1000531270,1000601420,1000601430 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.13.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.13.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000601440,1000601450,1000601460,1000601480,1000601500 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.14.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.14.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000741800,1000741820,1000741830,1000741840,1000741860 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.15.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.15.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000791970,1000822040,1000822060,1000822070,1000822080 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.16.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.16.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000190390,1000190400,1000190410,1000200400,1000200420 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.17.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.17.7TeV.log &
gmkspl_faser -n 300 -p -12  -t 1000200430,1000200440,1000200460,1000200480 --input-cross-sections freeN_merged/N.7TeV.300.xml -o AntiNuE_raw/AntiNuE.18.7TeV.300.xml -e 7000 >& AntiNuE_raw/AntiNuE.18.7TeV.log &