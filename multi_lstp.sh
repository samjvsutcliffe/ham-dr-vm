#!/bin/bash
read -p "Do you want to clear previous data? (y/n)" yn
case $yn in
    [yY] ) echo "Removing data";rm data/*; break;;
    [nN] ) break;;
esac
set -e
module load aocc/5.0.0
module load aocl/5.0.0
sbcl --dynamic-space-size 20000 --load "build_step.lisp" --quit
set +e


export SOLVER=IMPLICIT
export AGG=TRUE
export NAME=LSTP_NEW
export MPS=6
rm data_$NAME.csv
export REFINE=1
for s in DR
do
    export SOLVER=$s
    for l in 1 2 4 8 16 32 64 128 256 512
    do
        export LSTPS=$l
        sbatch batch_collapse.sh
    done
done
