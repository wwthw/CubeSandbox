#!/bin/bash
set -euo pipefail

# Cubelet start
# Keep the file paths consistent with the one-click deployment configuration.


export PATH="/usr/local/services/cubetoolbox/Cubelet/bin:${PATH}"

CUBELET_BIN="${CUBELET_BIN:-/usr/local/services/cubetoolbox/Cubelet/bin/cubelet}"
CUBELET_CONFIG="${CUBELET_CONFIG:-/usr/local/services/cubetoolbox/Cubelet/config/config.toml}"
DYNAMIC_CONF="${DYNAMIC_CONF:-/usr/local/services/cubetoolbox/Cubelet/dynamicconf/conf.yaml}"
NETWORK_AGENT_SOCKET="${NETWORK_AGENT_SOCKET:-/tmp/cube/network-agent-grpc.sock}"
NETWORK_AGENT_HEALTH="${NETWORK_AGENT_HEALTH:-127.0.0.1:19090}"

echo "Starting cubelet..."
echo "  CUBELET_BIN: ${CUBELET_BIN}"
echo "  CUBELET_CONFIG: ${CUBELET_CONFIG}"
echo "  DYNAMIC_CONF: ${DYNAMIC_CONF}"
echo "  NETWORK_AGENT_SOCKET: ${NETWORK_AGENT_SOCKET}"
echo "  NETWORK_AGENT_HEALTH: ${NETWORK_AGENT_HEALTH}"
echo "  PATH: ${PATH}"

if [[ ! -S "${NETWORK_AGENT_SOCKET}" ]]; then
    echo "Waiting for network-agent socket: ${NETWORK_AGENT_SOCKET}"
    for i in {1..60}; do
        if [[ -S "${NETWORK_AGENT_SOCKET}" ]]; then
            echo "network-agent socket ready"
            break
        fi
        sleep 1
    done
    if [[ ! -S "${NETWORK_AGENT_SOCKET}" ]]; then
        echo "ERROR: network-agent socket not found after 60s"
        exit 1
    fi
fi

echo "Checking network-agent health..."
for i in {1..30}; do
    if curl -fsS "http://${NETWORK_AGENT_HEALTH}/healthz" >/dev/null 2>&1; then
        echo "network-agent health check passed"
        break
    fi
    sleep 1
done


if mountpoint -q /sys/fs/bpf; then
    umount /sys/fs/bpf
fi
mkdir -p /sys/fs/bpf
mount -t bpf bpf /sys/fs/bpf -o mode=0700
echo "Mounted private bpffs at /sys/fs/bpf"

# start cubelet
exec "${CUBELET_BIN}" \
    --config "${CUBELET_CONFIG}" \
    --dynamic-conf-path "${DYNAMIC_CONF}"