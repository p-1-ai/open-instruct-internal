#!/bin/bash

# Redirect temp directories and caches to SSD storage
SSD_ROOT=/mnt/disks/ssd
mkdir -p "$SSD_ROOT/tmp"
mkdir -p "$SSD_ROOT/uv_cache"

# Set environment variables to use SSD for temp files and caches
export TMPDIR="$SSD_ROOT/tmp"
export TMP="$SSD_ROOT/tmp"
export TEMP="$SSD_ROOT/tmp"
export UV_CACHE_DIR="$SSD_ROOT/uv_cache"

# NCCL configuration for single-node multi-GPU (no InfiniBand)
# This VM doesn't have InfiniBand hardware, so we need to completely bypass
# the GCP gIB NCCL shim which causes segfaults when no IB hardware is present.

# Remove GCP's gIB library path to prevent the NCCL shim from loading
export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v '/usr/local/gib' | tr '\n' ':' | sed 's/:$//')

# Unset all GCP InfiniBand-related NCCL variables
unset NCCL_NET
unset NCCL_NET_PLUGIN
unset NCCL_NET_GDR_LEVEL
unset NCCL_IB_ADAPTIVE_ROUTING
unset NCCL_IB_FIFO_TC
unset NCCL_IB_QPS_PER_CONNECTION
unset NCCL_IB_TC
unset NCCL_CROSS_NIC
unset NCCL_TUNER_CONFIG_PATH
unset NCCL_NVLS_CHUNKSIZE
unset NCCL_P2P_NET_CHUNKSIZE

# Force NCCL to use socket-based communication
export NCCL_IB_DISABLE=1
export NCCL_DEBUG=INFO

accelerate launch \
    --mixed_precision bf16 \
    --num_processes 2 \
    --use_deepspeed \
    --deepspeed_config_file configs/ds_configs/stage3_no_offloading_accelerate.conf \
    --deepspeed_multinode_launcher standard \
    open_instruct/finetune.py \
    --exp_name tulu3_8b_sft \
    --model_name_or_path meta-llama/Llama-3.1-8B \
    --model_revision main \
    --tokenizer_name meta-llama/Llama-3.1-8B \
    --tokenizer_revision main \
    --use_slow_tokenizer \
    --chat_template tulu \
    --dataset_mixer_list allenai/tulu-3-sft-mixture 512 \
    --max_seq_length 4096 \
    --per_device_train_batch_size 2 \
    --gradient_accumulation_steps 32 \
    --learning_rate 5e-06 \
    --lr_scheduler_type linear \
    --warmup_ratio 0.03 \
    --weight_decay 0.0 \
    --num_train_epochs 2 \
    --output_dir /mnt/disks/ssd/tulu3_8b_sft \
    --use_flash_attn \
    --gradient_checkpointing \
    --checkpointing_steps epoch \
    --dataset_mix_dir /mnt/disks/ssd/tulu3_8b_sft \
    --report_to wandb \
    --with_tracking \
    --logging_steps 1 \
    --seed 8
