#!/bin/bash
#SBATCH --job-name=tulu3_8b_sft_single_node
#SBATCH --output=logs/tulu3_8b_sft_single_node_%j.log
#SBATCH --error=logs/tulu3_8b_sft_single_node_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=8
#SBATCH --mem=100G
#SBATCH --time=30:00:00

source .venv/bin/activate
PREFIX_DIR="/scratch/hieu/"

export TRITON_CACHE_DIR="$PREFIX_DIR/triton_cache"


accelerate launch \
    --mixed_precision bf16 \
    --num_processes 8 \
    --use_deepspeed \
    --deepspeed_config_file configs/ds_configs/stage3_no_offloading_accelerate.conf \
    open_instruct/finetune.py \
    --exp_name tulu3_8b_sft_single_node \
    --model_name_or_path meta-llama/Llama-3.1-8B \
    --model_revision main \
    --tokenizer_name meta-llama/Llama-3.1-8B \
    --tokenizer_revision main \
    --use_slow_tokenizer \
    --chat_template tulu \
    --dataset_mixer_list allenai/tulu-3-sft-mixture 1.0 \
    --max_seq_length 4096 \
    --per_device_train_batch_size 4 \
    --gradient_accumulation_steps 4 \
    --learning_rate 5e-06 \
    --lr_scheduler_type linear \
    --warmup_ratio 0.03 \
    --weight_decay 0.0 \
    --num_train_epochs 2 \
    --output_dir $PREFIX_DIR/tulu3_8b_sft_single_node \
    --dataset_local_cache_dir /data/hieu/tulu3_8b_sft/local_dataset_cache \
    --use_flash_attn \
    --gradient_checkpointing \
    --checkpointing_steps 3500 \
    --dataset_mix_dir $PREFIX_DIR/tulu3_8b_sft_single_node \
    --report_to wandb \
    --with_tracking \
    --logging_steps 1 \
    --seed 8

