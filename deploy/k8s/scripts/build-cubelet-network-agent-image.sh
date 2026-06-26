#!/usr/bin/env bash
set -euo pipefail

# Build Cubelet + Network-Agent Image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
IMAGE_DIR="${SCRIPT_DIR}/../images/cubelet-network-agent"

IMAGE_REGISTRY="${IMAGE_REGISTRY:-cube-sandbox}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"
PREBUILT_DIR="${PREBUILT_DIR:-${ROOT_DIR}/deploy/one-click/.work/prebuilt}"

echo "======================================"
echo "Building Cubelet-Network-Agent Image"
echo "======================================"
echo "Registry: ${IMAGE_REGISTRY}"
echo "Tag: ${IMAGE_TAG}"
echo "Prebuilt Dir: ${PREBUILT_DIR}"
echo "Image Dir: ${IMAGE_DIR}"
echo ""


check_prebuilt_binaries() {
    local binaries=(
        "cubelet"
        "cubecli"
        "containerd-shim-cube-rs"
        "cube-runtime"
        "network-agent"
    )
    
    echo "Checking prebuilt binaries..."
    for bin in "${binaries[@]}"; do
        local path="${PREBUILT_DIR}/${bin}"
        if [[ ! -f "${path}" ]]; then
            echo "ERROR: Binary not found: ${path}"
            echo "Please run build-release-bundle-builder.sh first"
            exit 1
        fi
        echo "  ✓ ${bin} ($(du -h "${path}" | cut -f1))"
    done
    echo ""
    echo "Note: containerd-shim-cube-rs includes hypervisor library (lib_support)"
    echo ""
}

# Preparing build context
prepare_build_context() {
    echo "Preparing build context..."

    cp "${PREBUILT_DIR}/cubelet" "${IMAGE_DIR}/cubelet"
    cp "${PREBUILT_DIR}/cubecli" "${IMAGE_DIR}/cubecli"

    if [[ -f "${ROOT_DIR}/Cubelet/contrib/nicl" ]]; then
        cp "${ROOT_DIR}/Cubelet/contrib/nicl" "${IMAGE_DIR}/nicl"
        chmod +x "${IMAGE_DIR}/nicl"
    fi
    
    if [[ -f "${ROOT_DIR}/Cubelet/contrib/cubelet-code-deploy.sh" ]]; then
        cp "${ROOT_DIR}/Cubelet/contrib/cubelet-code-deploy.sh" "${IMAGE_DIR}/cubelet-code-deploy.sh"
        chmod +x "${IMAGE_DIR}/cubelet-code-deploy.sh"
    fi
    
    if [[ -f "${ROOT_DIR}/Cubelet/contrib/unsquashfs" ]]; then
        cp "${ROOT_DIR}/Cubelet/contrib/unsquashfs" "${IMAGE_DIR}/unsquashfs"
        chmod +x "${IMAGE_DIR}/unsquashfs"
    else
        echo "WARNING: unsquashfs not found in Cubelet/contrib/"
    fi
    
    if [[ -f "${ROOT_DIR}/Cubelet/contrib/unsquashfs-dio" ]]; then
        cp "${ROOT_DIR}/Cubelet/contrib/unsquashfs-dio" "${IMAGE_DIR}/unsquashfs-dio"
        chmod +x "${IMAGE_DIR}/unsquashfs-dio"
    else
        echo "WARNING: unsquashfs-dio not found in Cubelet/contrib/"
    fi

    cp "${PREBUILT_DIR}/containerd-shim-cube-rs" "${IMAGE_DIR}/containerd-shim-cube-rs"
    cp "${PREBUILT_DIR}/cube-runtime" "${IMAGE_DIR}/cube-runtime"
    cp "${PREBUILT_DIR}/network-agent" "${IMAGE_DIR}/network-agent"
    cp "${ROOT_DIR}/deploy/one-click/config-cube.toml" "${IMAGE_DIR}/config-cube.toml"
    cp "${ROOT_DIR}/configs/single-node/network-agent.yaml" "${IMAGE_DIR}/network-agent.yaml"

    if [[ -f "${ROOT_DIR}/Cubelet/config/snapshot.sh" ]]; then
        cp "${ROOT_DIR}/Cubelet/config/snapshot.sh" "${IMAGE_DIR}/snapshot.sh"
        chmod +x "${IMAGE_DIR}/snapshot.sh"
    fi
    
    echo "  ✓ All files copied to ${IMAGE_DIR}"
    echo ""
}

# Building Docker image
build_image() {
    echo "Building Docker image..."
    
    docker build \
        -t "${IMAGE_REGISTRY}/cubelet-network-agent:${IMAGE_TAG}" \
        -t "${IMAGE_REGISTRY}/cubelet-network-agent:latest" \
        -f "${IMAGE_DIR}/Dockerfile" \
        "${IMAGE_DIR}"
    
    echo "  ✓ Image built successfully"
    echo ""
}

# Push image to registry Registry
push_image() {
    if [[ "${PUSH_IMAGE:-false}" == "true" ]]; then
        echo "Pushing image to registry..."
        docker push "${IMAGE_REGISTRY}/cubelet-network-agent:${IMAGE_TAG}"
        docker push "${IMAGE_REGISTRY}/cubelet-network-agent:latest"
        echo "  ✓ Image pushed successfully"
        echo ""
    fi
}

# cleanup
cleanup() {
    echo "Cleaning up build context..."
    
    rm -f \
        "${IMAGE_DIR}/cubelet" \
        "${IMAGE_DIR}/cubecli" \
        "${IMAGE_DIR}/containerd-shim-cube-rs" \
        "${IMAGE_DIR}/cube-runtime" \
        "${IMAGE_DIR}/network-agent" \
        "${IMAGE_DIR}/nicl" \
        "${IMAGE_DIR}/cubelet-code-deploy.sh" \
        "${IMAGE_DIR}/unsquashfs" \
        "${IMAGE_DIR}/unsquashfs-dio" \
        "${IMAGE_DIR}/config-cube.toml" \
        "${IMAGE_DIR}/network-agent.yaml" \
        "${IMAGE_DIR}/snapshot.sh"
    
    echo "  ✓ Cleanup done"
    echo ""
}

# show image info
show_image_info() {
    echo "======================================"
    echo "Image Information"
    echo "======================================"
    docker images "${IMAGE_REGISTRY}/cubelet-network-agent" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    
    echo "Usage:"
    echo "  # Pull image"
    echo "  docker pull ${IMAGE_REGISTRY}/cubelet-network-agent:${IMAGE_TAG}"
    echo ""
    echo "  # Deploy to Kubernetes (recommended)"
    echo "  kubectl apply -f deploy/k8s/manifests/namespace.yaml"
    echo "  kubectl apply -f deploy/k8s/manifests/configmaps/"
    echo "  kubectl apply -f deploy/k8s/manifests/daemonsets/"
    echo ""
    echo "  # Or run locally for testing:"
    echo "  docker run -d --name cubelet-test \\"
    echo "    --privileged \\"
    echo "    -v /tmp/cube:/tmp/cube \\"
    echo "    -v /data/cubelet:/data/cubelet \\"
    echo "    -v /dev/kvm:/dev/kvm \\"
    echo "    -v /usr/local/services/cubetoolbox/Cubelet/config:/usr/local/services/cubetoolbox/Cubelet/config \\"
    echo "    -v /usr/local/services/cubetoolbox/Cubelet/dynamicconf:/usr/local/services/cubetoolbox/Cubelet/dynamicconf \\"
    echo "    ${IMAGE_REGISTRY}/cubelet-network-agent:${IMAGE_TAG}"
    echo ""
}

main() {
    check_prebuilt_binaries
    prepare_build_context
    build_image
    push_image
    cleanup
    show_image_info
    
    echo "======================================"
    echo "Build Completed Successfully!"
    echo "======================================"
}

main "$@"