# Cubelet + Network-Agent Combined Image 

FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    e2fsprogs \
    util-linux \
    uidmap \
    bash \
    coreutils \
    procps \
    iputils-ping \
    iproute2 \
    tcpdump \
    linux-tools-common \
    linux-tools-generic \
    iperf3 \
    net-tools \
    bridge-utils \
    ethtool \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
    /usr/local/bin \
    /usr/local/services/cubetoolbox/Cubelet/bin \
    /usr/local/services/cubetoolbox/Cubelet/config \
    /usr/local/services/cubetoolbox/Cubelet/dynamicconf \
    /usr/local/services/cubetoolbox/network-agent/bin \
    /usr/local/services/cubetoolbox/network-agent/state \
    /usr/local/services/cubetoolbox/cube-shim/bin \
    /usr/local/services/cubetoolbox/cube-shim/conf \
    /usr/local/services/cubetoolbox/cube-hypervisor \
    /usr/local/services/cubetoolbox/cube-snapshot \
    /data/cubelet \
    /data/log/Cubelet \
    /data/log/CubeShim \
    /data/log/CubeVmm \
    /data/cube-shim/disks \
    /data/snapshot_pack/disks \
    /run/cube-containers/shared/sandboxes \
    /tmp/cube


COPY cubelet /usr/local/services/cubetoolbox/Cubelet/bin/cubelet
COPY cubecli /usr/local/services/cubetoolbox/Cubelet/bin/cubecli
COPY nicl /usr/local/services/cubetoolbox/Cubelet/bin/nicl
COPY cubelet-code-deploy.sh /usr/local/services/cubetoolbox/Cubelet/bin/cubelet-code-deploy.sh
COPY unsquashfs /usr/local/services/cubetoolbox/Cubelet/bin/unsquashfs
COPY unsquashfs-dio /usr/local/services/cubetoolbox/Cubelet/bin/unsquashfs-dio
COPY containerd-shim-cube-rs /usr/local/services/cubetoolbox/cube-shim/bin/containerd-shim-cube-rs
COPY cube-runtime /usr/local/services/cubetoolbox/cube-shim/bin/cube-runtime
COPY network-agent /usr/local/services/cubetoolbox/network-agent/bin/network-agent
COPY config-cube.toml /usr/local/services/cubetoolbox/cube-shim/conf/config-cube.toml
COPY network-agent.yaml /usr/local/services/cubetoolbox/network-agent/network-agent.yaml
COPY snapshot.sh /usr/local/services/cubetoolbox/Cubelet/config/snapshot.sh


RUN chmod +x \
    /usr/local/services/cubetoolbox/Cubelet/bin/cubelet \
    /usr/local/services/cubetoolbox/Cubelet/bin/cubecli \
    /usr/local/services/cubetoolbox/Cubelet/bin/nicl \
    /usr/local/services/cubetoolbox/Cubelet/bin/cubelet-code-deploy.sh \
    /usr/local/services/cubetoolbox/Cubelet/bin/unsquashfs \
    /usr/local/services/cubetoolbox/Cubelet/bin/unsquashfs-dio \
    /usr/local/services/cubetoolbox/cube-shim/bin/containerd-shim-cube-rs \
    /usr/local/services/cubetoolbox/cube-shim/bin/cube-runtime \
    /usr/local/services/cubetoolbox/network-agent/bin/network-agent

COPY start-network-agent.sh /usr/local/bin/start-network-agent.sh
COPY start-cubelet.sh /usr/local/bin/start-cubelet.sh
RUN chmod +x /usr/local/bin/start-network-agent.sh /usr/local/bin/start-cubelet.sh

RUN ln -sf /usr/local/services/cubetoolbox/cube-shim/bin/cube-runtime /usr/local/bin/cube-runtime
RUN ln -sf /usr/local/services/cubetoolbox/cube-shim/bin/containerd-shim-cube-rs /usr/local/bin/containerd-shim-cube-rs

RUN chmod +x /usr/local/services/cubetoolbox/Cubelet/config/snapshot.sh

WORKDIR /data/cubelet

ENTRYPOINT ["/usr/local/bin/start-cubelet.sh"]
CMD ["--config", "/usr/local/services/cubetoolbox/Cubelet/config/config.toml"]