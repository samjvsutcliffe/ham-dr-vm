#!/bin/bash
read -p "Do you want to clear previous data? (y/n)" yn
#case $yn in
#    [yY] ) echo "Removing data";rm data/*; break;;
#    [nN] ) break;;
#esac
set -e
module load aocc/5.0.0
module load aocl/5.0.0
#sbcl --dynamic-space-size 20000 --load "build_step.lisp" --quit
set +e

export SOLVER=DR
export LSTPS=10
export MPS=6
export AGG=TRUE
export NAME=MESHREFINE
rm data_MESHREFINE.csv
for h in 0.5 1 2 4 6 8 10 12 14 16
do
    export REFINE=$h
    sbatch batch_collapse.sh
done
