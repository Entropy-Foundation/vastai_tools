#!/usr/bin/env zsh
# Destroy every active VastAI instance after a safety confirmation prompt.
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: destroy_all_instances.zsh [--yes]

Fetches all VastAI instance IDs and issues `vastai destroy instance <id>` for
each one. Prompts for confirmation unless `--yes` is supplied.
USAGE
}

force=false
while (( $# )); do
  case "$1" in
    -y|--yes|--force)
      force=true
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      print_usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ -f .env ]]; then
  source .env
  export VAST_API_KEY
fi

if [[ -z ${VAST_API_KEY:-} ]]; then
  echo 'Warning: VAST_API_KEY is not set. Vast.ai CLI commands may fail.' >&2
fi

if ! raw_instances=$(vastai show instances --raw 2>&1); then
  printf 'Failed to list instances: %s\n' "$raw_instances" >&2
  exit 1
fi

if ! id_output=$(
  print -r -- "$raw_instances" | python3 -c "import json, sys
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError as exc:
    sys.stderr.write(f'Failed to parse vastai output as JSON: {exc}\n')
    sys.exit(1)
for item in (data or []):
    inst_id = item.get('id')
    if inst_id is not None:
        print(inst_id)"
); then
  exit 1
fi

typeset -a instance_ids
instance_ids=(${(f)id_output})

if (( ${#instance_ids} == 0 )); then
  echo 'No instances found.'
  exit 0
fi

echo 'Instances scheduled for destruction:'
for inst_id in "${instance_ids[@]}"; do
  printf '  - %s\n' "$inst_id"
done

if [[ $force == false ]]; then
  printf 'Destroy all listed instances? [y/N]: '
  if ! read -q; then
    echo
    echo 'Aborted.'
    exit 1
  fi
  echo
fi

typeset -a failed
for inst_id in "${instance_ids[@]}"; do
  printf 'Destroying instance %s...\n' "$inst_id"
  if ! vastai destroy instance "$inst_id"; then
    printf 'Failed to destroy instance %s\n' "$inst_id" >&2
    failed+=("$inst_id")
  fi
done

if (( ${#failed} > 0 )); then
  echo 'Completed with errors.' >&2
  echo 'Instances that could not be destroyed:' >&2
  for inst_id in "${failed[@]}"; do
    printf '  - %s\n' "$inst_id" >&2
  done
  exit 1
fi

echo 'All instances destroyed.'
