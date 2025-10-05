#!/usr/bin/env bash

# Query VastAI for offers that have at least the requested amount of system RAM
# Sorted by hourly price (ascending)

set -euo pipefail

MIN_RAM_GB="${1:-64}"

if [[ ! $MIN_RAM_GB =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Usage: $0 [minimum_ram_gb]"
    echo "Example: $0 128"
    exit 1
fi

printf "Searching for offers with >= %s GB RAM...\n" "$MIN_RAM_GB"
printf "%0.s=" {1..46}; printf '\n'

# Load environment variables for API key if available
if [[ -f .env ]]; then
    # shellcheck source=/dev/null
    source .env
    export VAST_API_KEY
fi

QUERY="cpu_ram>=$MIN_RAM_GB rentable=true verified=true"

if [[ -n "${VAST_API_KEY:-}" ]]; then
    offers=$(vastai search offers "$QUERY" --order 'dph_total' --raw)
else
    offers=$(vastai search offers "$QUERY" --order 'dph_total' --raw)
fi

if [[ -z "$offers" || "$offers" == "[]" ]]; then
    echo "No offers found that meet the RAM requirement."
    exit 0
fi

echo ""
printf "%-10s %-20s %-7s %-10s %-12s %-12s %-20s\n" "ID" "GPU" "#GPUs" "CPU RAM" "Price/hr" "Reliability" "Location"
printf '%0.0s-' {1..104}; printf '\n'

echo "$offers" | jq -r '
    sort_by(.dph_total) |
    .[:15] |
    .[] |
    [
        .id,
        .gpu_name,
        .num_gpus,
        (.cpu_ram / 1024),
        .dph_total,
        .reliability,
        .geolocation
    ] | @tsv
' | while IFS=$'\t' read -r id gpu num_gpus cpu_ram_gb price reliability location; do
    cpu_ram_formatted=$(printf "%.1fGB" "$cpu_ram_gb")
    price_formatted=$(printf "\$%.3f" "$price")
    reliability_formatted=$(printf "%.3f" "$reliability")
    printf "%-10s %-20s %-7s %-10s %-12s %-12s %-20s\n" \
        "$id" "$gpu" "$num_gpus" "$cpu_ram_formatted" "$price_formatted" "$reliability_formatted" "$location"
done

echo ""
echo "Usage:"
echo "  ./query_ram.sh [minimum_ram_gb]        # Query offers with at least the given RAM"
echo "  ./start_llm_instance.sh <offer_id>      # Create LLM-ready instance"
echo "  ./start_minimal_instance.sh <offer_id>  # Create minimal Ubuntu instance"
echo ""
printf "Example: ./query_ram.sh %s\n" "$MIN_RAM_GB"
