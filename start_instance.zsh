#!/usr/bin/env zsh

# VastAI Instance Creation Script
# Creates an RTX 5090 instance running vLLM server with Gemma model

set -e  # Exit on error

# Check if offer ID provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <offer_id>"
    echo "Example: $0 26128186"
    echo ""
    echo "Get offer IDs from: poetry run python query_gpus.py"
    exit 1
fi

OFFER_ID="$1"

# Load environment variables
if [[ -f .env ]]; then
    source .env
    export VAST_API_KEY
    export HUGGING_FACE_HUB_TOKEN
else
    echo "Error: .env file not found"
    echo "Make sure .env contains HUGGING_FACE_HUB_TOKEN"
    exit 1
fi

if [[ -z "$HUGGING_FACE_HUB_TOKEN" ]]; then
    echo "Error: HUGGING_FACE_HUB_TOKEN not found in .env file"
    exit 1
fi

if [[ -z "$VAST_API_KEY" ]]; then
    echo "Error: VAST_API_KEY not found in .env file"
    exit 1
fi

echo "Creating VastAI instance from offer: $OFFER_ID"
echo "==========================================="

# Create the onstart script content
ONSTART_SCRIPT="#!/bin/bash
set -e
echo 'Starting vLLM server setup...'

# Install any missing dependencies if needed
pip install --no-cache-dir vllm

# Start the vLLM server
echo 'Launching vLLM OpenAI-compatible server...'
python3 -m vllm.entrypoints.openai.api_server \\
  --model ISTA-DASLab/gemma-3-27b-it-GPTQ-4b-128g \\
  --max-model-len 32768 \\
  --tensor-parallel-size 1 \\
  --host 0.0.0.0 \\
  --port 8080 \\
  --trust-remote-code

echo 'vLLM server started on port 8080'
"

# Create the instance using vastai CLI
echo "Creating instance with:"
echo "  - Offer ID: $OFFER_ID"
echo "  - Image: vllm/vllm-openai:latest"
echo "  - Disk: 50GB"
echo "  - Port: 8080 (vLLM server)"
echo "  - SSH: Enabled"
echo ""

# Execute the vastai create instance command
vastai create instance "$OFFER_ID" \
    --image "vllm/vllm-openai:latest" \
    --disk 50 \
    --env "-e HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN -p 8080:8080" \
    --ssh \
    --direct \
    --label "vllm-gemma-server" \
    --onstart-cmd "$ONSTART_SCRIPT" \
    --raw

echo ""
echo "Instance creation command completed!"
echo ""
echo "Next steps:"
echo "1. Check instance status: vastai show instances"
echo "2. Monitor logs: vastai logs <instance_id>"
echo "3. SSH access: vastai ssh-url <instance_id>"
echo "4. vLLM server will be available on port 8080 once fully started"
echo ""
echo "To delete instance: vastai destroy instance <instance_id>"