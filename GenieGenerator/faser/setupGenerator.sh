#!/bin/bash

ATHENA_VERSION=22.0.49
GSL_VERSION=2.7-30ba4
PYTHIA6_VERSION=429.2-5d3d1
LHAPDF6_VERSION=6.2.3-adb82
#LHAPDF5_VERSION=5.9.1-76a09/x86_64-centos7-gcc62-opt
LOG4CPP_VERSION=2.8.3p1-72f76

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export GENIE_HOME=$SCRIPT_DIR/../..
export GENIE=$SCRIPT_DIR/..

if [[ -n "$1" ]]; then
    SYS_CONFIG=$1
else
    SYS_CONFIG="x86_64-centos7-gcc8-opt"
fi

mkdir -p TPythia6_build
cd TPythia6_build

fsetup Athena, $ATHENA_VERSION

TPYTHIA6_PATH=$PWD/../TPythia6_install
cmake -DCMAKE_INSTALL_PREFIX=$TPYTHIA6_PATH ../GenieGenerator/faser
make install

cd ..

GSL_PATH=/cvmfs/sft.cern.ch/lcg/releases/GSL/$GSL_VERSION/$SYS_CONFIG

export PYTHIA6_PATH=/cvmfs/sft.cern.ch/lcg/releases/MCGenerators/pythia6/$PYTHIA6_VERSION/$SYS_CONFIG

export LHAPDF6_PATH=/cvmfs/sft.cern.ch/lcg/releases/MCGenerators/lhapdf/$LHAPDF6_VERSION/$SYS_CONFIG
#export LHAPDF5_PATH=/cvmfs/sft.cern.ch/lcg/releases/MCGenerators/lhapdf/$LHAPDF5_VERSION
export LHAPATH=$GENIE/data/evgen/pdfs
export LHAPDF_DATA_PATH=$GENIE/data/evgen/pdfs/:$LHAPDF_DATA_PATH

LOG4CPP_PATH=/cvmfs/sft.cern.ch/lcg/releases/MCGenerators/log4cpp/$LOG4CPP_VERSION/$SYS_CONFIG


export PATH=$PATH:\
$GSL_PATH/bin:\
$GENIE_HOME/run_3_04/bin

#export LD_LIBRARY_PATH=$LHAPDF5_PATH/lib:$LD_LIBRARY_PATH:\
export LD_LIBRARY_PATH=$LHAPDF6_PATH/lib:\
$LOG4CPP_PATH/lib:\
#$PYTHIA6_PATH/lib:\
$TPYTHIA6_PATH/lib:\
$GENIE_HOME/run_3_04/lib:\
$LD_LIBRARY_PATH

export LINUX_SYS_INCLUDES=-I$TPYTHIA6_PATH/include/TPythia6
export SYSLIBS=-L$TPYTHIA6_PATH/lib
