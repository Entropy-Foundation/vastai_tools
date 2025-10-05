#!/usr/bin/env bash

# Check VastAI account balance and user info

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

echo "VastAI Account Information:"
echo "=========================="
vastai show user

echo ""
echo "Recent Billing History:"
echo "======================"
vastai show invoices | head -10

echo ""
echo "Account Management:"
echo "- Add funds: https://cloud.vast.ai/billing/"
echo "- View usage: https://cloud.vast.ai/billing/usage/"
echo "- Account settings: https://cloud.vast.ai/account/"
