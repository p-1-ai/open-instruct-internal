#!/bin/bash
#SBATCH --job-name=tulu3_8b_sft
#SBATCH --output=logs/tulu3_8b_sft_%j.log
#SBATCH --error=logs/tulu3_8b_sft_%j.err
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=8
#SBATCH --mem=250G
#SBATCH --time=50:00:00

export MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
echo $(scontrol show hostnames "$SLURM_JOB_NODELIST")
export MASTER_PORT=29502
export NUM_PROCESSES=$((SLURM_NNODES * 8))

export HF_HOME="/scratch/hf_home"
export HF_TOKEN="<HF_TOKEN>"
export DATASET_LOCAL_CACHE_DIR="/scratch/hieu/tulu3_8b_sft/local_dataset_cache/"

# Run scripts/train/tulu3/launch_finetune.sh 5 times to account for variance
for i in {1..5}; do
    export PREFIX_DIR="/scratch/hieu/tulu3_8b_sft_${i}"
    export OUTPUT_DIR="${PREFIX_DIR}/outputs"
    export EXP_NAME="tulu3_8b_sft_${i}"
    export DATASET_MIX_DIR="${PREFIX_DIR}/dataset_mix"
    export WANDB_PROJECT="tulu3_8b_sft_${i}"
    export TRITON_CACHE_DIR="$PREFIX_DIR/triton_cache"
    srun -l mkdir -p $TRITON_CACHE_DIR

    srun -l scripts/train/tulu3/launch_finetune.sh

    echo "Finished finetuning $EXP_NAME"
    echo ""
    echo ""
    echo ""
    echo ""
done
