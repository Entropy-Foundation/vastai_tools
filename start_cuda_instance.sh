#!/usr/bin/env zsh

# VastAI CUDA Instance Creation Script
# Launches an instance prepped with NVIDIA drivers and installs the newest CUDA Toolkit supported by the host driver

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

echo "Creating VastAI CUDA instance from offer: $OFFER_ID"
echo "====================================================="

ONSTART_SCRIPT=$(cat <<'EOS'
#!/bin/bash
set -euo pipefail

log() {
  echo "[cuda-setup] $1"
}

export DEBIAN_FRONTEND=noninteractive

if ! command -v nvidia-smi >/dev/null 2>&1; then
  log "nvidia-smi is not available. Cannot detect driver version."
  exit 1
fi

DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1 | tr -d ' ')
if [[ -z "$DRIVER_VERSION" ]]; then
  log "Failed to determine NVIDIA driver version."
  exit 1
fi

log "Detected NVIDIA driver version: $DRIVER_VERSION"

# Mapping of CUDA Toolkit versions to their minimum required driver versions (Linux)
CUDA_MATRIX=(
  "12-4:550.54.14"
  "12-3:545.23.06"
  "12-2:535.86.10"
  "12-1:530.30.02"
  "12-0:525.60.13"
  "11-8:520.61.05"
  "11-7:515.43.04"
  "11-6:510.47.03"
  "11-5:495.29.05"
  "11-4:470.82.01"
  "11-3:465.19.01"
)

CHOSEN_VERSION=""
for entry in "${CUDA_MATRIX[@]}"; do
  VERSION="${entry%%:*}"
  MIN_DRIVER="${entry##*:}"
  if dpkg --compare-versions "$DRIVER_VERSION" ge "$MIN_DRIVER"; then
    CHOSEN_VERSION="$VERSION"
    break
  fi
done

if [[ -z "$CHOSEN_VERSION" ]]; then
  log "Driver version $DRIVER_VERSION is too old for the supported CUDA Toolkit matrix."
  exit 1
fi

HUMAN_VERSION="${CHOSEN_VERSION//-/.}"
log "Selecting CUDA Toolkit version $HUMAN_VERSION based on driver capability."

apt-get update
apt-get install -y wget gnupg2 curl >/dev/null

if ! dpkg -s cuda-keyring >/dev/null 2>&1; then
  log "Installing NVIDIA CUDA repository keyring"
  wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
  dpkg -i cuda-keyring_1.1-1_all.deb >/dev/null
  rm -f cuda-keyring_1.1-1_all.deb
fi

apt-get update
log "Installing cuda-toolkit-$CHOSEN_VERSION"
apt-get install -y "cuda-toolkit-$CHOSEN_VERSION"

cat <<'PROFILE' > /etc/profile.d/cuda.sh
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
PROFILE
chmod +x /etc/profile.d/cuda.sh

if /usr/local/cuda/bin/nvcc --version >/dev/null 2>&1; then
  NVCC_INFO=$(/usr/local/cuda/bin/nvcc --version | grep "release")
  log "CUDA Toolkit installation complete: ${NVCC_INFO}"
else
  log "CUDA Toolkit installation completed, but nvcc was not detected in /usr/local/cuda/bin."
fi

log "CUDA setup finished."
EOS
)

echo "Creating instance with:"
echo "  - Offer ID: $OFFER_ID"
echo "  - Image: library/ubuntu:22.04"
echo "  - Disk: 50GB"
echo "  - SSH: Enabled"
echo ""

vastai create instance "$OFFER_ID" \
    --image "library/ubuntu:22.04" \
    --disk 50 \
    --ssh \
    --direct \
    --label "cuda-toolkit" \
    --onstart-cmd "$ONSTART_SCRIPT" \
    --raw

echo ""
echo "Instance creation command completed!"
echo ""
echo "Next steps:"
echo "1. Check instance status: vastai show instances"
echo "2. Monitor logs: vastai logs <instance_id>"
echo "3. SSH access: vastai ssh-url <instance_id>"
echo "4. CUDA toolkit installed under /usr/local/cuda (after login: source /etc/profile.d/cuda.sh)"
echo ""
echo "To delete instance: vastai destroy instance <instance_id>"
