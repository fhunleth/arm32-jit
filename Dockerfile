FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG AUTOCONF_VERSION=2.72
ARG HOST_ERLANG_VERSION=27.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        binutils-arm-linux-gnueabihf \
        build-essential \
        ca-certificates \
        clang \
        curl \
        file \
        g++-arm-linux-gnueabihf \
        gcc-arm-linux-gnueabihf \
        gdb-multiarch \
        git \
        iproute2 \
        m4 \
        ncurses-dev \
        openssh-client \
        pkg-config \
        procps \
        qemu-user \
        rsync \
        wget \
        xz-utils && \
    ln -sf /usr/arm-linux-gnueabihf/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3 && \
    rm -rf /lib/arm-linux-gnueabihf /usr/lib/arm-linux-gnueabihf && \
    ln -sfn /usr/arm-linux-gnueabihf/lib /lib/arm-linux-gnueabihf && \
    ln -sfn /usr/arm-linux-gnueabihf/lib /usr/lib/arm-linux-gnueabihf && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q "https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.xz" && \
    tar -xf "autoconf-${AUTOCONF_VERSION}.tar.xz" && \
    cd "autoconf-${AUTOCONF_VERSION}" && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    cd / && \
    rm -rf "/autoconf-${AUTOCONF_VERSION}" "/autoconf-${AUTOCONF_VERSION}.tar.xz"

RUN curl -fsSL https://raw.githubusercontent.com/kerl/kerl/master/kerl -o /usr/local/bin/kerl && \
    chmod +x /usr/local/bin/kerl && \
    kerl cleanup all && \
    kerl build-install "${HOST_ERLANG_VERSION}" "${HOST_ERLANG_VERSION}" "/usr/local/lib/erlang/${HOST_ERLANG_VERSION}"

ENV HOST_ERLANG_VERSION=${HOST_ERLANG_VERSION}
ENV PATH="/usr/local/lib/erlang/${HOST_ERLANG_VERSION}/bin:${PATH}"
WORKDIR /workspace/arm32-jit

CMD ["/bin/bash"]
