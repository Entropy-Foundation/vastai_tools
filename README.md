# VastAI Management Scripts

Simple zsh scripts for managing VastAI GPU instances with vLLM server deployment.

## Prerequisites

- VastAI CLI installed (`vastai`)
- `.env` file with required tokens (see below)

## Configuration

Copy the template and fill in your API keys:
```bash
cp .env.template .env
```

Then edit `.env` with your actual keys:
- **VAST_API_KEY**: Get from https://cloud.vast.ai/api/
- **HUGGING_FACE_HUB_TOKEN**: Get from https://huggingface.co/settings/tokens

## Usage

### Check Account Balance
```bash
./check_balance.zsh
```
Shows account information, credit balance, and recent billing history.

### Find RTX 5090 Offers
```bash
./query_gpus.zsh
```
Lists available RTX 5090 single GPU servers sorted by price (lowest first).

### Create Instance
```bash
./start_instance.zsh <offer_id>
```
Creates a new instance with vLLM server running Gemma-3-27b model on port 8080.

### List Your Instances
```bash
./list_instances.zsh
```
Shows all your running instances with status and connection info.

## Example Workflow

```bash
# 1. Check your account balance
./check_balance.zsh

# 2. Find available GPU offers
./query_gpus.zsh

# 3. Create instance from an offer (use ID from step 2)
./start_instance.zsh 26128186

# 4. Monitor your instances
./list_instances.zsh

# 5. Connect to vLLM server
# Once running, the server will be available at:
# http://<instance_ip>:8080
```

## vLLM Server Details

The scripts automatically deploy a vLLM OpenAI-compatible API server with:
- **Model**: ISTA-DASLab/gemma-3-27b-it-GPTQ-4b-128g
- **Port**: 8080
- **API**: OpenAI-compatible endpoints
- **Max Context**: 32,768 tokens

## Instance Management

Use VastAI CLI commands for additional management:
```bash
# SSH into instance
vastai ssh-url <instance_id>

# Check logs
vastai logs <instance_id>

# Stop instance
vastai stop instance <instance_id>

# Delete instance
vastai destroy instance <instance_id>
```