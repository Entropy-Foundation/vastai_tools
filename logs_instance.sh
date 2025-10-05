#!/usr/bin/env bash
# Fetches logs for a Vast.ai instance with optional tail/filter parameters
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: logs_instance.sh <instance-id> [--tail N] [--filter PATTERN] [--daemon]

Loads the Vast API key from .env, then calls `vastai logs` for the specified
instance. Optional flags:
  --tail N        Limit output to the last N lines (passes through to vastai)
  --filter TEXT   Filter log output using Vast.ai's server-side grep
  --daemon        Show daemon system logs instead of container logs
USAGE
}

if (( $# == 0 )) || [[ ${1:-} == "-h" ]] || [[ ${1:-} == "--help" ]]; then
  print_usage
  exit $(( $# == 0 ? 1 : 0 ))
fi

instance_id=""
tail_arg=""
filter_arg=""
daemon_flag=false

instance_id=$1
shift

while (( $# > 0 )); do
  case $1 in
    --tail)
      if (( $# < 2 )); then
        echo 'Error: --tail requires a numeric argument.' >&2
        exit 1
      fi
      tail_arg=$2
      shift 2
      ;;
    --filter)
      if (( $# < 2 )); then
        echo 'Error: --filter requires a pattern argument.' >&2
        exit 1
      fi
      filter_arg=$2
      shift 2
      ;;
    --daemon)
      daemon_flag=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      printf 'Error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [[ -f .env ]]; then
  source .env
  export VAST_API_KEY
fi

if [[ -z ${VAST_API_KEY:-} ]]; then
  echo 'Warning: VAST_API_KEY is not set. Vast.ai CLI commands may fail.' >&2
fi

cmd=(vastai logs "$instance_id")

if [[ -n $tail_arg ]]; then
  cmd+=(--tail "$tail_arg")
fi

if [[ -n $filter_arg ]]; then
  cmd+=(--filter "$filter_arg")
fi

if $daemon_flag; then
  cmd+=(--daemon-logs)
fi

printf 'Fetching logs for instance %s...\n' "$instance_id"
exec "${cmd[@]}"
