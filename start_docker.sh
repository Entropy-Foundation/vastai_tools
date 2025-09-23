#!/bin/bash

# Available LLM models:
# meta-llama/Meta-Llama-3.1-8B-Instruct
# mistralai/Mistral-7B-Instruct-v0.3
# meta-llama/Llama-4-Scout-17B-16E-Instruct
# ISTA-DASLab/gemma-3-27b-it-GPTQ-4b-128g

# Load environment variables from .env file
source .env

docker run --rm -it --gpus all \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -e HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN \
  vllm/vllm-openai \
  --model ISTA-DASLab/gemma-3-27b-it-GPTQ-4b-128g \
  --max-model-len 32768 \
  --tensor-parallel-size 1