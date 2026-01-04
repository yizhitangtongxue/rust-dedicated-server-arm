FROM ubuntu:20.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building Box86/Box64 and running SteamCMD
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    python3 \
    wget \
    curl \
    tar \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python

# Enable 32-bit ARM architecture (armhf) for Box86 (needed for SteamCMD)
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install -y \
    libc6:armhf \
    libstdc++6:armhf \
    libncurses5:armhf \
    libgcc-s1:armhf \
    libx11-6:armhf \
    && rm -rf /var/lib/apt/lists/*

# Install x86_64 libraries for Rust Server (via Box64)
# Plus libraries mentioned in the guide (libgoogle-perftools4 for libtcmalloc_minimal)
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    libgoogle-perftools4:arm64 \
    gosu \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    && rm -rf /var/lib/apt/lists/*

# Build Box86 (for SteamCMD - 32-bit x86 emulator)
WORKDIR /tmp
RUN git clone https://github.com/ptitSeb/box86 && \
    mkdir box86/build && cd box86/build && \
    cmake .. -DARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && rm -rf box86

# Build Box64 (for Rust Server - 64-bit x86_64 emulator)
WORKDIR /tmp
RUN git clone https://github.com/ptitSeb/box64 && \
    mkdir box64/build && cd box64/build && \
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && rm -rf box64

# Setup user
RUN useradd -m -d /home/steam -s /bin/bash steam
WORKDIR /home/steam

# Create directory for SteamCMD and Server
RUN mkdir -p /home/steam/steamcmd /home/steam/rust && \
    chown -R steam:steam /home/steam/steamcmd /home/steam/rust

# Download SteamCMD
USER steam
WORKDIR /home/steam/steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

USER root
# Copy entrypoint script
COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

# Environment variables
ENV BOX86_LOG=0
ENV BOX64_LOG=0

# Improved stability parameters (Minimal set for Unity on Box64)
ENV BOX64_DYNAREC_STRONGMEM=3

ENTRYPOINT ["/home/steam/entrypoint.sh"]
