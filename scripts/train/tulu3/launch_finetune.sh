#!/bin/bash

echo "NUM_PROCESSES: $NUM_PROCESSES, SLURM_NNODES: $SLURM_NNODES, SLURM_NODEID: $SLURM_NODEID, MASTER_ADDR: $MASTER_ADDR, MASTER_PORT: $MASTER_PORT"

source .venv/bin/activate

mkdir -p $PREFIX_DIR/tulu3_8b_sft/local_dataset_cache

# copy dataset cache to compute local storage for faster I/O
cp -r /data/hieu/tulu3_8b_sft/local_dataset_cache/6e728152cc/ $PREFIX_DIR/tulu3_8b_sft/local_dataset_cache

accelerate launch \
    --main_process_ip $MASTER_ADDR \
    --main_process_port $MASTER_PORT \
    --machine_rank $SLURM_NODEID \
    --num_processes $NUM_PROCESSES \
    --num_machines $SLURM_NNODES \
    --mixed_precision bf16 \
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
    --dataset_mixer_list allenai/tulu-3-sft-mixture 1.0 \
    --max_seq_length 4096 \
    --per_device_train_batch_size 4 \
    --learning_rate 5e-06 \
    --lr_scheduler_type linear \
    --warmup_ratio 0.03 \
    --weight_decay 0.0 \
    --num_train_epochs 2 \
    --output_dir $PREFIX_DIR/tulu3_8b_sft \
    --dataset_local_cache_dir $PREFIX_DIR/tulu3_8b_sft/local_dataset_cache \
    --use_flash_attn \
    --gradient_checkpointing \
    --checkpointing_steps 3500 \
    --dataset_mix_dir $PREFIX_DIR/tulu3_8b_sft \
    --report_to wandb \
    --with_tracking \
    --logging_steps 1 \
    --seed 8

