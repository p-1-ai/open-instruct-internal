#!/bin/bash
#SBATCH --job-name=tulu3_8b_sft
#SBATCH --output=logs/tulu3_8b_sft_%j.log
#SBATCH --error=logs/tulu3_8b_sft_%j.err
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=8
#SBATCH --mem=250G
#SBATCH --time=10:00:00

export MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
echo $(scontrol show hostnames "$SLURM_JOB_NODELIST")
export MASTER_PORT=29502
export NUM_PROCESSES=$((SLURM_NNODES * 8))

export HF_HOME="/scratch/hf_home"
export HF_TOKEN="<HF_TOKEN>"

# Optional (good practice): set cache dir to avoid NFS hangs
export PREFIX_DIR="/scratch/hieu"

export TRITON_CACHE_DIR="$PREFIX_DIR/triton_cache"
srun -l mkdir -p $TRITON_CACHE_DIR

srun -l scripts/train/tulu3/launch_finetune.sh
