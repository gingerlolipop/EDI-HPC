#!/bin/bash

#SBATCH --account=def-ncoops_gpu
#SBATCH --gres=gpu:1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=0-01:00

# build venv for python
module load python/3.12
virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index upgrade pip
pip install --no-index xarray

time python hello_world.py
