#!/bin/bash
read -p "Do you want to clear previous data? (y/n)" yn
case $yn in
    [yY] ) echo "Removing data";rm -r data/*; break;;
    [nN] ) break;;
esac
set -e
module load aocc/5.0.0
module load aocl/5.0.0
#sbcl --dynamic-space-size 32000 --disable-debugger --load "build_step.lisp" --quit
set +e


export SOLVER=IMPLICIT
export AGG=TRUE
export NAME=LSTP
export MPS=6
export REFINE=1
# rm data_$NAME.csv
for s in DR IMPLICIT
do
    export SOLVER=$s
    for l in 1 2 4 8 16 32 64 128 256
    do
        export LSTPS=$l
        for r in 1 # 2 3
        do
            sbatch batch_collapse.sh
        done
    done
done
