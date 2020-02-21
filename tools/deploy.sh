#!/bin/bash

set -e

info() {
    echo '[INFO] ' "$@"
}

setup_env() {
    SUDO="sudo"
    if [ $(id -u) -eq 0 ]; then
        SUDO=""
    fi
}

setup_verify_bind_address() {
    if [ -n "${INSTALL_SUANPAN_ROCKET_VERSION}" ]; then
        K3S_BIND_ADDRESS="${INSTALL_SUANPAN_ROCKET_VERSION}"
    else
        K3S_BIND_ADDRESS="0.0.0.0"
    fi
    info "Bind Address: ${K3S_BIND_ADDRESS}"
}

setup_verify_version() {
    if [ -n "${INSTALL_SUANPAN_ROCKET_VERSION}" ]; then
        K3S_VERSION="${INSTALL_SUANPAN_ROCKET_VERSION}"
    else
        K3S_VERSION=$(curl -sfL "https://suanpan-public.oss-cn-shanghai.aliyuncs.com/k3s/version.txt")
    fi
    OSS_K3S_VERSION=$(echo ${K3S_VERSION} | sed "s/+/-/g")
    info "Version: ${K3S_VERSION}"
}

setup_verify_arch() {
    if [ -z "${ARCH}" ]; then
        ARCH=$(uname -m)
    fi
    case ${ARCH} in
        amd64)
            ARCH="amd64"
            SUFFIX=""
            ;;
        x86_64)
            ARCH="amd64"
            SUFFIX=""
            ;;
        arm64)
            ARCH="arm64v8"
            SUFFIX=-${ARCH}
            ;;
        aarch64)
            ARCH="arm64v8"
            SUFFIX=-${ARCH}
            ;;
        arm*)
            ARCH="arm32v7"
            SUFFIX=-${ARCH}hf
            ;;
        *)
            fatal "Unsupported architecture ${ARCH}"
    esac
    info "ARCH: ${ARCH}"
}

setup_tmp() {
    TMP_DIR=$(mktemp -d -t k3s-install.XXXXXXXXXX)
    TMP_HASH=${TMP_DIR}/k3s.hash
    TMP_BIN=${TMP_DIR}/k3s.bin
    TMP_IMAGES=${TMP_DIR}/images.tar
    cleanup() {
        code=$?
        set +e
        trap - EXIT
        rm -rf ${TMP_DIR}
        exit $code
    }
    trap cleanup INT EXIT
}

download_binary() {
    info "Downloading Binary..."
    curl -o ${TMP_BIN} -fL "https://suanpan-public.oss-cn-shanghai.aliyuncs.com/k3s/${OSS_K3S_VERSION}/bin/k3s-${ARCH}"
}

setup_binary() {
    BIN_DIR="/usr/local/bin"
    chmod 755 ${TMP_BIN}
    info "Installing k3s to ${BIN_DIR}/k3s"
    $SUDO chown root:root ${TMP_BIN}
    $SUDO mv -f ${TMP_BIN} ${BIN_DIR}/k3s

    if command -v getenforce > /dev/null 2>&1; then
        if [ "Disabled" != $(getenforce) ]; then
	    info 'SELinux is enabled, setting permissions'
	    if ! $SUDO semanage fcontext -l | grep "${BIN_DIR}/k3s" > /dev/null 2>&1; then
	        $SUDO semanage fcontext -a -t bin_t "${BIN_DIR}/k3s"
	    fi
	    $SUDO restorecon -v ${BIN_DIR}/k3s > /dev/null
        fi
    fi
}

download_images() {
    info "Downloading Images..."
    curl -o ${TMP_IMAGES} -fL "https://suanpan-public.oss-cn-shanghai.aliyuncs.com/k3s/${OSS_K3S_VERSION}/deployments/${ARCH}/images.tar" || info "No Preloaded Images Available."
}

setup_images() {
    info "Loading Images..."
    if [ -f "${TMP_IMAGES}" ]; then
        docker load -i ${TMP_IMAGES}
    else
        info "No Preloaded Images Available."
    fi
}

prepare() {
    setup_env
    setup_tmp
    setup_verify_arch
    setup_verify_version
}

download() {
    download_binary
    download_images
}

install() {
    setup_binary
    setup_images

    export INSTALL_K3S_VERSION=${K3S_VERSION}
    export INSTALL_K3S_SKIP_DOWNLOAD=true
    export INSTALL_K3S_EXEC="--docker --bind-address=${K3S_BIND_ADDRESS} --disable-network-policy"
    curl -sfL "https://suanpan-public.oss-cn-shanghai.aliyuncs.com/k3s/${OSS_K3S_VERSION}/deployments/install.sh" | sh -
}

check() {
    info "Checking..."
    k3s check-config
}

{
    prepare
    download
    install
    check
}
