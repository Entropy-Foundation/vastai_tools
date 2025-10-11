#!/usr/bin/env zsh

# VastAI Keyless Icicle Instance Creation Script
# Launches an instance using the davidsupra/keyless-icicle Docker image

set -e  # Exit on error

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
else
    echo "Error: .env file not found"
    exit 1
fi

if [[ -z "$VAST_API_KEY" ]]; then
    echo "Error: VAST_API_KEY not found in .env file"
    exit 1
fi

echo "Creating VastAI Keyless Icicle instance from offer: $OFFER_ID"
echo "============================================================="

ONSTART_SCRIPT="#!/bin/bash
set -e
echo 'Keyless Icicle environment is now available.'
echo 'Refer to the davidsupra/keyless-icicle documentation for service endpoints and usage.'
"

echo "Creating instance with:"
echo "  - Offer ID: $OFFER_ID"
echo "  - Image: davidsupra/keyless-icicle:cuda12"
echo "  - Disk: 50GB"
echo "  - SSH: Enabled"
echo ""

vastai create instance "$OFFER_ID" \
    --image "davidsupra/keyless-icicle:cuda12" \
    --disk 50 \
    --ssh \
    --direct \
    --label "keyless-icicle" \
    --onstart-cmd "$ONSTART_SCRIPT" \
    --raw

echo ""
echo "Instance creation command completed!"
echo ""
echo "Next steps:"
echo "1. Check instance status: vastai show instances"
echo "2. Monitor logs: vastai logs <instance_id>"
echo "3. SSH access: vastai ssh-url <instance_id>"
echo "4. Review the container documentation for exposed services and credentials"
echo ""
echo "To delete instance: vastai destroy instance <instance_id>"
