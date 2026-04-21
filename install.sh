#!/bin/sh
# Airwallex CLI installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/awx-cyrus-pastelero/airwallex-cli/main/install.sh | sh
#
# Environment variables:
#   AWX_VERSION   pin a specific release (default: latest, e.g. v0.1.0)
#   AWX_INSTALL_DIR   install location (default: $HOME/.local/bin)

set -eu

REPO="awx-cyrus-pastelero/airwallex-cli"
BIN_NAME="airwallex"
INSTALL_DIR="${AWX_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${AWX_VERSION:-latest}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
err()  { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }

detect_platform() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "$os" in
        darwin) os="darwin" ;;
        linux)  os="linux" ;;
        *)      err "Unsupported OS: $os (supported: darwin, linux)" ;;
    esac

    case "$arch" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) err "Unsupported architecture: $arch (supported: amd64, arm64)" ;;
    esac

    echo "${os}-${arch}"
}

main() {
    command -v curl >/dev/null 2>&1 || err "curl is required but not installed"

    platform=$(detect_platform)
    asset="${BIN_NAME}-${platform}"

    if [ "$VERSION" = "latest" ]; then
        url="https://github.com/${REPO}/releases/latest/download/${asset}"
    else
        url="https://github.com/${REPO}/releases/download/${VERSION}/${asset}"
    fi

    info "Detected platform: ${platform}"
    info "Downloading ${asset} from ${VERSION} release..."

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    if ! curl -fsSL -o "${tmp}/${BIN_NAME}" "$url"; then
        err "Failed to download from $url"
    fi

    chmod +x "${tmp}/${BIN_NAME}"

    # Strip macOS Gatekeeper quarantine attribute (silently ignored on Linux)
    if [ "$(uname -s)" = "Darwin" ]; then
        xattr -cr "${tmp}/${BIN_NAME}" 2>/dev/null || true
    fi

    mkdir -p "$INSTALL_DIR"
    mv "${tmp}/${BIN_NAME}" "${INSTALL_DIR}/${BIN_NAME}"

    info "Installed ${BIN_NAME} to ${INSTALL_DIR}/${BIN_NAME}"

    installed_version=$("${INSTALL_DIR}/${BIN_NAME}" --no-telemetry --version 2>/dev/null || echo "unknown")
    info "Version: ${installed_version}"

    case ":$PATH:" in
        *":${INSTALL_DIR}:"*)
            info "Run \`${BIN_NAME} --help\` to get started."
            ;;
        *)
            warn "${INSTALL_DIR} is not on your PATH."
            warn "Add it by appending the following to your shell profile (~/.zshrc, ~/.bashrc):"
            warn ""
            warn "    export PATH=\"${INSTALL_DIR}:\$PATH\""
            warn ""
            warn "Or run the binary directly: ${INSTALL_DIR}/${BIN_NAME} --help"
            ;;
    esac
}

main "$@"
