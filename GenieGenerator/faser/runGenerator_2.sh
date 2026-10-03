#!/bin/bash

cd $GENIE_OUTPUT
gevgen_hadron -n 10000 -p 211 -t 1000080160 -k 0.2 --seed 9839389
