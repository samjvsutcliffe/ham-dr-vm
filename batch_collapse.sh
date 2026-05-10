#!/bin/bash

# Request resources:
#SBATCH --time=6:00:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p shared
#SBATCH -n 1                    # number of MPI ranks
#SBATCH --cpus-per-task=16   # number of MPI ranks per CPU socket
#SBATCH --mem=20G


#mem-per-cpu=1G
module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0
export GC_THREADS=16
export OMP_NUM_THREADS=16
./worker --dynamic-space-size 20GB
