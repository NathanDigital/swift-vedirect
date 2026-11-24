# Build image: Ubuntu 26.04 LTS with the Swift toolchain from swift.org.

# ubuntu:26.04, multi-arch index digest (resolved 2026-11-17).
FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db

# Swift toolchain build dependencies, per swiftlang/swift-docker 6.4/ubuntu/26.04.
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
        binutils \
        binutils-gold \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        libarchive-tools \
        libc6-dev \
        libcurl4-openssl-dev \
        libedit2 \
        libgcc-15-dev \
        libncurses5-dev \
        libpython3-dev \
        libsqlite3-0 \
        libstdc++-15-dev \
        libxml2-dev \
        libz3-dev \
        pkg-config \
        tzdata \
        unzip \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>
ARG SWIFT_SIGNING_FINGERPRINT=52BB7E3DE28A71BE22EC05FFEF80A866B47A981F
ARG SWIFT_VERSION=6.4.2

# Keyring from https://www.swift.org/keys/all-keys.asc
COPY swift-keys.asc /tmp/swift-keys.asc

RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
        arm64) ARCH_SUFFIX=-aarch64 ;; \
        amd64) ARCH_SUFFIX= ;; \
        *) echo >&2 "unsupported architecture"; exit 1 ;; \
    esac; \
    TAG="swift-${SWIFT_VERSION}-RELEASE"; \
    NAME="${TAG}-ubuntu26.04${ARCH_SUFFIX}"; \
    URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2604${ARCH_SUFFIX}/${TAG}/${NAME}.tar.gz"; \
    export GNUPGHOME="$(mktemp -d)"; \
    curl -fsSL "$URL" -o /tmp/swift.tar.gz; \
    curl -fsSL "$URL.sig" -o /tmp/swift.tar.gz.sig; \
    gpg --batch --quiet --import /tmp/swift-keys.asc; \
    gpg --batch --status-fd 1 --verify /tmp/swift.tar.gz.sig /tmp/swift.tar.gz \
        | grep -q "^\[GNUPG:\] VALIDSIG .* ${SWIFT_SIGNING_FINGERPRINT}\$" \
        || { echo >&2 "Swift tarball not signed by ${SWIFT_SIGNING_FINGERPRINT}"; exit 1; }; \
    bsdtar -xzf /tmp/swift.tar.gz -C / --strip-components=1; \
    chmod -R o+r /usr/lib/swift; \
    rm -rf "$GNUPGHOME" /tmp/swift.tar.gz /tmp/swift.tar.gz.sig /tmp/swift-keys.asc

RUN swift --version

# Debian packaging tools.
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
        build-essential \
        debhelper \
        systemd \
    && rm -rf /var/lib/apt/lists/*
