#!/bin/bash

mkdir -p $GENIE/../run_3_04/bin
mkdir -p $GENIE/../run_3_04/lib
mkdir -p $GENIE/../run_3_04/include


cd $GENIE
./configure --enable-faser --enable-apfel --prefix=$GENIE/../run_3_04 --with-pythia6-lib=$PYTHIA6_PATH/lib --with-lhapdf6-lib=$LHAPDF6_PATH/lib --with-lhapdf6-inc=$LHAPDF6_PATH/inc --disable-lhapdf5 --enable-lhapdf6 
make -j clean
make -j distclean
make -j
make -j install
