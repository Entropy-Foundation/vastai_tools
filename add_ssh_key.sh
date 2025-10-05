#!/usr/bin/env bash
# Adds an SSH public key to Vast.ai using the CLI
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: add_ssh_key.sh [path-to-public-key]

Reads the given SSH public key (defaults to ~/.ssh/id_supra.pub) and uploads it to Vast.ai
using the CLI command `vastai create ssh-key`.
USAGE
}

# Allow a quick help flag
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  print_usage
  exit 0
fi

# Load Vast.ai API key from .env if available, matching other scripts
if [[ -f .env ]]; then
  source .env
  export VAST_API_KEY
fi

key_path=${1:-"$HOME/.ssh/id_supra.pub"}

if [[ ! -f $key_path ]]; then
  printf 'Error: public key file not found at %s\n' "$key_path" >&2
  exit 1
fi

pub_key=$(<"$key_path")
pub_key=${pub_key//$'\r'/}
pub_key=${pub_key//$'\n'/}

if [[ -z $pub_key ]]; then
  printf 'Error: public key file %s is empty\n' "$key_path" >&2
  exit 1
fi

if ! output=$(vastai create ssh-key "$pub_key" 2>&1); then
  printf 'Failed to upload SSH key: %s\n' "$output" >&2
  exit 1
fi

echo "$output"

if echo "$output" | grep -qi 'already exists'; then
  echo 'SSH key already exists on your Vast.ai account.'
else
  echo 'SSH key uploaded to Vast.ai.'
fi
