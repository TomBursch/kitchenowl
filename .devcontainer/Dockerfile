FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG FLUTTER_VERSION=stable

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies for backend (matches backend/Dockerfile builder) and Flutter
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Build / backend deps
        build-essential gcc g++ pkg-config cmake ninja-build cargo \
        libffi-dev libpcre2-dev libre2-dev libxml2-dev libxslt-dev \
        libopenblas-dev liblapack-dev gfortran autoconf automake \
        zlib1g-dev libjpeg62-turbo-dev libssl-dev libsqlite3-dev \
        libexpat1-dev libicu-dev libxml2 libexpat1 media-types \
        # Flutter / general
        git curl wget unzip zip xz-utils ca-certificates gnupg \
        libstdc++6 libglu1-mesa clang libgtk-3-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv (Python package/version manager) system-wide
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Install Flutter SDK to /opt/flutter, owned by vscode user
ARG FLUTTER_HOME=/opt/flutter
RUN git clone --depth 1 -b ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && chown -R vscode:vscode ${FLUTTER_HOME} \
    && git config --global --add safe.directory ${FLUTTER_HOME}

ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Pre-warm Flutter as the vscode user (downloads Dart SDK, accepts no analytics)
USER vscode
RUN flutter config --no-analytics \
    && flutter config --enable-web --enable-linux-desktop \
    && flutter precache --web --linux \
    && flutter doctor -v || true

USER root
