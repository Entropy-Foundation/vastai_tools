#!/usr/bin/env bash

# List all VastAI instances

# Load environment variables for API key
if [[ -f .env ]]; then
    source .env
    export VAST_API_KEY
fi

echo "Your VastAI Instances:"
echo "====================="

if [[ -n "$VAST_API_KEY" ]]; then
    vastai show instances
else
    vastai show instances
fi

echo ""
echo "Commands:"
echo "- Check logs: vastai logs <instance_id>"
echo "- SSH access: vastai ssh-url <instance_id>"
echo "- Stop: vastai stop instance <instance_id>"
echo "- Delete: vastai destroy instance <instance_id>"
