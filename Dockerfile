FROM ubuntu:22.04

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
    gcc-arm-linux-gnueabihf \
    && rm -rf /var/lib/apt/lists/*

# Enable 32-bit ARM architecture (armhf) for Box86
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
# Note: Box64 often uses native arm64 libs where possible, but some specific libs might be needed.
# For now we rely on Box64's ability to wrap native libs.
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    libgoogle-perftools4 \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Build Box86 (for SteamCMD)
# Targeting ARM64 host to run x86 (32-bit) binaries
WORKDIR /tmp
RUN git clone https://github.com/ptitSeb/box86 && \
    mkdir box86/build && cd box86/build && \
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_ASM_COMPILER=arm-linux-gnueabihf-gcc && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && rm -rf box86

# Build Box64 (for Rust Server)
# Targeting ARM64 host to run x86_64 binaries
WORKDIR /tmp
RUN git clone https://github.com/ptitSeb/box64 && \
    mkdir box64/build && cd box64/build && \
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && rm -rf box64

# Setup user
RUN useradd -m -d /home/steam -s /bin/bash steam
# USER steam (We stay as root to fix permissions in entrypoint)
WORKDIR /home/steam

# Create directory for SteamCMD and Server
RUN mkdir -p /home/steam/steamcmd /home/steam/rust

# Download SteamCMD
WORKDIR /home/steam/steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Copy entrypoint script
COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

# Environment variables
ENV LD_LIBRARY_PATH=/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:/usr/lib/arm-linux-gnueabihf:/usr/lib/aarch64-linux-gnu
# Ensure Box86 and Box64 are used
ENV BOX86_LOG=0
ENV BOX64_LOG=0

ENTRYPOINT ["/home/steam/entrypoint.sh"]
