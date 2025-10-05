#!/usr/bin/env bash

# Query VastAI for RTX 5090 single GPU servers
# Sorted by price (lowest first)

echo "Searching for RTX 5090 Single GPU Servers..."
echo "=============================================="

# Load environment variables for API key
if [[ -f .env ]]; then
    source .env
    export VAST_API_KEY
fi

# Get raw JSON data and process it (use API key from .env if available)
if [[ -n "$VAST_API_KEY" ]]; then
    offers=$(vastai search offers 'num_gpus=1 gpu_name=RTX_5090 rentable=true verified=true' --order 'dph_total' --raw)
else
    offers=$(vastai search offers 'num_gpus=1 gpu_name=RTX_5090 rentable=true verified=true' --order 'dph_total' --raw)
fi

if [[ -z "$offers" ]] || [[ "$offers" == "[]" ]]; then
    echo "No RTX 5090 offers found."
    exit 0
fi

# Format and display results
echo ""
printf "%-10s %-20s %-7s %-10s %-12s %-12s %-20s\n" "ID" "GPU" "#GPUs" "Price/hr" "DL Speed" "Reliability" "Location"
echo "----------------------------------------------------------------------------------------------------"

# Use jq to extract and format the data (simplified)
echo "$offers" | jq -r '
sort_by(.dph_total) |
.[:15] |
.[] |
[.id, .gpu_name, .num_gpus, ("$" + (.dph_total | tostring)), (.dlperf | tostring), (.reliability | tostring), .geolocation] |
@tsv
' | while IFS=$'\t' read -r id gpu num_gpus price dlperf reliability location; do
    # Format the output with proper spacing
    printf "%-10s %-20s %-7s %-10s %-12.1f %-12.3f %-20s\n" \
        "$id" "$gpu" "$num_gpus" "${price:0:6}" "${dlperf:0:5}" "${reliability:0:5}" "$location"
done

echo ""
echo "Usage:"
echo "  ./start_llm_instance.sh <offer_id>      # Create LLM-ready instance"
echo "  ./start_minimal_instance.sh <offer_id>  # Create minimal Ubuntu instance"
    echo "  ./list_instances.sh               # List your current instances"
echo ""
echo "Example: ./start_llm_instance.sh $( echo "$offers" | jq -r 'sort_by(.dph_total) | .[0].id' )"
