#!/usr/bin/env zsh
# Copies a local file to a Vast.ai instance using scp
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scp_instance.zsh <instance-id> <local-file>

Attaches the default Vast.ai SSH public key (from ~/.ssh/id_supra.pub), retrieves
connection info via the Vast.ai CLI, then copies the given file to the instance's
/root directory using scp.
USAGE
}

if (( $# == 0 )) || [[ ${1:-} == "-h" ]] || [[ ${1:-} == "--help" ]]; then
  print_usage
  exit $(( $# == 0 ? 1 : 0 ))
fi

if (( $# != 2 )); then
  echo 'Error: script expects exactly two arguments.' >&2
  print_usage
  exit 1
fi

instance_id=$1
local_file=$2
pub_key_path="$HOME/.ssh/id_supra.pub"

if [[ ! -f $local_file ]]; then
  printf 'Error: local file not found at %s\n' "$local_file" >&2
  exit 1
fi

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

remote_target="/root/${local_file:t}"

echo "Copying $local_file to $user@$host:$remote_target (port $port)..."
scp -i "$private_key_path" -P "$port" "$local_file" "$user@$host:$remote_target"
