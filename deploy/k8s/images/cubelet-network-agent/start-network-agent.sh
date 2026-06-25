#!/bin/bash
set -euo pipefail

# Network-Agent start
# Keep the file paths consistent with the one-click deployment configuration.

NETWORK_AGENT_BIN="${NETWORK_AGENT_BIN:-/usr/local/services/cubetoolbox/network-agent/bin/network-agent}"
CUBELET_CONFIG="${CUBELET_CONFIG:-/usr/local/services/cubetoolbox/Cubelet/config/config.toml}"
GRPC_LISTEN="${GRPC_LISTEN:-unix:///tmp/cube/network-agent-grpc.sock}"
TAP_FD_LISTEN="${TAP_FD_LISTEN:-unix:///tmp/cube/network-agent-tap.sock}"
STATE_DIR="${STATE_DIR:-/usr/local/services/cubetoolbox/network-agent/state}"
HEALTH_LISTEN="${HEALTH_LISTEN:-127.0.0.1:19090}"

echo "Starting network-agent..."
echo "  NETWORK_AGENT_BIN: ${NETWORK_AGENT_BIN}"
echo "  CUBELET_CONFIG: ${CUBELET_CONFIG}"
echo "  GRPC_LISTEN: ${GRPC_LISTEN}"
echo "  TAP_FD_LISTEN: ${TAP_FD_LISTEN}"
echo "  STATE_DIR: ${STATE_DIR}"
echo "  HEALTH_LISTEN: ${HEALTH_LISTEN}"

if [[ ! -f "${CUBELET_CONFIG}" ]]; then
    echo "Waiting for cubelet config: ${CUBELET_CONFIG}"
    for i in {1..30}; do
        if [[ -f "${CUBELET_CONFIG}" ]]; then
            break
        fi
        sleep 1
    done
    if [[ ! -f "${CUBELET_CONFIG}" ]]; then
        echo "ERROR: cubelet config not found after 30s"
        exit 1
    fi
fi

mkdir -p "${STATE_DIR}"
mkdir -p /tmp/cube

if mountpoint -q /sys/fs/bpf; then
    umount /sys/fs/bpf
fi
mkdir -p /sys/fs/bpf
mount -t bpf bpf /sys/fs/bpf -o mode=0700
echo "Mounted private bpffs at /sys/fs/bpf"

# start network-agent
exec "${NETWORK_AGENT_BIN}" \
    --cubelet-config "${CUBELET_CONFIG}" \
    --grpc-listen "${GRPC_LISTEN}" \
    --tap-fd-listen "${TAP_FD_LISTEN}" \
    --state-dir "${STATE_DIR}" \
    --health-listen "${HEALTH_LISTEN}"