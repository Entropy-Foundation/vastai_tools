#!/usr/bin/env zsh
# Checks whether the vLLM server is responding on a Vast.ai instance
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: check_vllm.zsh <instance-id> [path-to-public-key]

Attaches the default Vast.ai SSH key (or the provided path), retrieves the
instance's SSH connection info, and probes http://127.0.0.1:8080/health over SSH
to confirm the vLLM server is running.
USAGE
}

if (( $# == 0 )) || [[ ${1:-} == "-h" ]] || [[ ${1:-} == "--help" ]]; then
  print_usage
  exit $(( $# == 0 ? 1 : 0 ))
fi

instance_id=$1
pub_key_path=${2:-"$HOME/.ssh/id_supra.pub"}

if [[ -f .env ]]; then
  source .env
  export VAST_API_KEY
fi

if [[ -z ${VAST_API_KEY:-} ]]; then
  echo 'Warning: VAST_API_KEY is not set. Vast.ai CLI commands may fail.' >&2
fi

if [[ ! -f $pub_key_path ]]; then
  printf 'Error: public key file not found at %s\n' "$pub_key_path" >&2
  exit 1
fi

private_key_path=${pub_key_path%.pub}
if [[ $private_key_path == $pub_key_path ]]; then
  private_key_path=$pub_key_path
fi

if [[ ! -f $private_key_path ]]; then
  printf 'Error: private key file not found at %s\n' "$private_key_path" >&2
  exit 1
fi

pub_key=$(<"$pub_key_path")
pub_key=${pub_key//$'\r'/}
pub_key=${pub_key//$'\n'/}

if [[ -z $pub_key ]]; then
  printf 'Error: public key file %s is empty\n' "$pub_key_path" >&2
  exit 1
fi

if ! attach_output=$(vastai attach ssh "$instance_id" "$pub_key" 2>&1); then
  if echo "$attach_output" | grep -qi 'already'; then
    echo 'SSH key already attached to this instance.'
  else
    printf 'Failed to attach SSH key: %s\n' "$attach_output" >&2
    exit 1
  fi
else
  echo "$attach_output"
fi

if ! ssh_url=$(vastai ssh-url "$instance_id" 2>&1); then
  printf 'Failed to fetch ssh-url: %s\n' "$ssh_url" >&2
  exit 1
fi
ssh_url=${ssh_url##*$'\n'}

if [[ $ssh_url != ssh://* ]]; then
  printf 'Unexpected ssh-url output: %s\n' "$ssh_url" >&2
  exit 1
fi

userhost=${ssh_url#ssh://}
user=${userhost%%@*}
hostport=${userhost#*@}
host=${hostport%%:*}
port=${hostport##*:}

if [[ -z $host ]] || [[ -z $port ]]; then
  printf 'Could not parse host/port from %s\n' "$ssh_url" >&2
  exit 1
fi

echo "Checking vLLM health on $user@$host (port $port)..."
health_cmd="curl -sSf http://127.0.0.1:8080/health"

if health_output=$(ssh -i "$private_key_path" -p "$port" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=10 "$user@$host" "$health_cmd" 2>&1); then
  echo 'vLLM server is responding:'
  echo "$health_output"
  exit 0
fi

echo 'Primary health check failed; attempting fallback probe...' >&2
fallback_cmd="curl -sSf http://127.0.0.1:8080/v1/models"
if health_output=$(ssh -i "$private_key_path" -p "$port" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=10 "$user@$host" "$fallback_cmd" 2>&1); then
  echo 'vLLM server responded to /v1/models:'
  echo "$health_output"
  exit 0
fi

printf 'Failed to verify vLLM server status. Last error:\n%s\n' "$health_output" >&2
exit 1
