#!/bin/bash

BEAKER_IMAGE="${1:-nathanl/open_instruct_auto}"

echo "Using Beaker image: $BEAKER_IMAGE"

# Redirect temp directories and caches to SSD storage
SSD_ROOT=/mnt/disks/ssd
mkdir -p "$SSD_ROOT/tmp"
mkdir -p "$SSD_ROOT/uv_cache"

# Set environment variables to use SSD for temp files and caches
export TMPDIR="$SSD_ROOT/tmp"
export TMP="$SSD_ROOT/tmp"
export TEMP="$SSD_ROOT/tmp"
export UV_CACHE_DIR="$SSD_ROOT/uv_cache"

# Configure NCCL for single GPU mode (avoid segfault from network plugin loading)
# The segfault happens when NCCL shim tries to load libnccl-net_internal.so
# Prevent NCCL shim from being used at all
unset NCCL_NET
unset NCCL_NET_PLUGIN
# Disable the NCCL shim entirely to prevent segfaults
export NCCL_SHIM_DISABLE=1
# Disable network features (not needed for single GPU)
export NCCL_IB_DISABLE=1
export NCCL_P2P_DISABLE=1
# Keep shared memory enabled (needed for local communication)
export NCCL_SHM_DISABLE=0
# Enable debug to diagnose issues
export NCCL_DEBUG=INFO

accelerate launch \
    --mixed_precision bf16 \
    --num_processes 1 \
    --use_deepspeed \
    --deepspeed_config_file configs/ds_configs/stage3_no_offloading_accelerate.conf \
    --deepspeed_multinode_launcher standard \
    open_instruct/finetune.py \
    --exp_name tulu3_8b_sft \
    --model_name_or_path Qwen/Qwen3-0.6B \
    --model_revision main \
    --tokenizer_revision main \
    --use_slow_tokenizer \
    --chat_template tulu \
    --dataset_mixer_list allenai/tulu-3-sft-mixture 512 \
    --max_seq_length 4096 \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps 2 \
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

# {'alo': 'meta-llama/Llama-3.1-8B', 'revision': 'main', 'from_tf': False, 'config': LlamaConfig {
#   "architectures": [
#     "LlamaForCausalLM"
#   ],
#   "attention_bias": false,
#   "attention_dropout": 0.0,
#   "bos_token_id": 128000,
#   "dtype": "bfloat16",
#   "eos_token_id": 128001,
#   "head_dim": 128,
#   "hidden_act": "silu",
#   "hidden_size": 4096,
#   "initializer_range": 0.02,
#   "intermediate_size": 14336,
#   "max_position_embeddings": 131072,
#   "mlp_bias": false,
#   "model_type": "llama",
#   "num_attention_heads": 32,
#   "num_hidden_layers": 32,
#   "num_key_value_heads": 8,
#   "pretraining_tp": 1,
#   "rms_norm_eps": 1e-05,
#   "rope_scaling": {
#     "factor": 8.0,
#     "high_freq_factor": 4.0,
#     "low_freq_factor": 1.0,
#     "original_max_position_embeddings": 8192,
#     "rope_type": "llama3"
#   },
#   "rope_theta": 500000.0,
#   "tie_word_embeddings": false,
#   "transformers_version": "4.57.1",
#   "use_cache": true,
#   "vocab_size": 128256
# }
# , 'trust_remote_code': False, 'low_cpu_mem_usage': False, 'torch_dtype': torch.bfloat16, 'attn_implementation': 'flash_attention_2'}
