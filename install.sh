#!/bin/sh
# Airwallex CLI installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/awx-cyrus-pastelero/airwallex-cli/main/install.sh | sh
#
# Environment variables:
#   AWX_VERSION       pin a specific release (default: latest, e.g. v0.1.0)
#   AWX_INSTALL_DIR   install location (default: $HOME/.local/bin)

set -eu

REPO="awx-cyrus-pastelero/airwallex-cli"
BIN_NAME="airwallex"
INSTALL_DIR="${AWX_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${AWX_VERSION:-latest}"

# Colors only when stdout is a terminal — keeps output clean in CI / log files.
if [ -t 1 ]; then
    BLUE='\033[1;34m'
    YELLOW='\033[1;33m'
    RED='\033[1;31m'
    RESET='\033[0m'
else
    BLUE=''
    YELLOW=''
    RED=''
    RESET=''
fi

info() { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$*"; }
warn() { printf '%s!!%s  %s\n'  "$YELLOW" "$RESET" "$*" >&2; }
err()  { printf '%sxx%s  %s\n'  "$RED"    "$RESET" "$*" >&2; exit 1; }

# Detect the platform and emit the asset-name fragment used in release
# filenames. We deliberately use `mac-os` / `x86_64` rather than
# `darwin` / `amd64` so the asset names match every other major CLI's
# convention — installer scripts and package mirrors slot in without a
# custom URL template.
detect_platform() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "$os" in
        darwin) os_label="mac-os" ;;
        linux)  os_label="linux" ;;
        *)      err "Unsupported OS: $os (supported: darwin, linux)" ;;
    esac

    case "$arch" in
        x86_64|amd64)   arch_label="x86_64" ;;
        arm64|aarch64)  arch_label="arm64" ;;
        *) err "Unsupported architecture: $arch (supported: x86_64, arm64)" ;;
    esac

    echo "${os_label}_${arch_label}"
}

# Suggest the right shell rc file based on $SHELL — falls back to a generic hint.
suggest_rc_file() {
    case "${SHELL:-}" in
        */zsh)  echo "~/.zshrc" ;;
        */bash) echo "~/.bashrc" ;;
        */fish) echo "~/.config/fish/config.fish" ;;
        *)      echo "your shell's startup file" ;;
    esac
}

# Pre-flight: make sure we can actually write to INSTALL_DIR before downloading
# anything. Fail fast with a useful message instead of cryptic mv permission errors.
check_writable() {
    dir="$1"
    if [ -d "$dir" ]; then
        if [ ! -w "$dir" ]; then
            err "$(printf '%s' "Cannot write to $dir.
    Re-run with sudo, or pick a writable location:
        AWX_INSTALL_DIR=\$HOME/.local/bin curl -fsSL ... | sh")"
        fi
    else
        parent=$(dirname "$dir")
        if [ ! -w "$parent" ]; then
            err "$(printf '%s' "Cannot create $dir (parent $parent is not writable).
    Re-run with sudo, or pick a writable location:
        AWX_INSTALL_DIR=\$HOME/.local/bin curl -fsSL ... | sh")"
        fi
    fi
}

# Resolve the latest release tag from the GitHub API. Asset filenames are
# versioned (airwallex_0.1.0_...), so we can't use the
# /releases/latest/download/<asset> redirect — we have to know the
# concrete version first.
resolve_latest_version() {
    api_url="https://api.github.com/repos/${REPO}/releases/latest"
    # `grep -E "tag_name"` then a portable cut to extract the value works
    # without jq, which is rarely pre-installed on minimal Linux images.
    tag=$(curl -fsSL "$api_url" 2>/dev/null \
        | grep -E '"tag_name"[[:space:]]*:' \
        | head -n 1 \
        | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    if [ -z "$tag" ]; then
        err "Failed to resolve latest version from $api_url"
    fi
    echo "$tag"
}

main() {
    command -v curl >/dev/null 2>&1 || err "curl is required but not installed"
    command -v tar  >/dev/null 2>&1 || err "tar is required but not installed"

    if [ "$VERSION" = "latest" ]; then
        VERSION=$(resolve_latest_version)
        info "Resolved latest version: ${VERSION}"
    fi

    # Strip a leading "v" so the asset filename matches the package version
    # embedded in pyproject.toml (e.g. v0.1.0 -> 0.1.0).
    version_no_v=${VERSION#v}

    platform=$(detect_platform)
    asset="airwallex_${version_no_v}_${platform}.tar.gz"
    url="https://github.com/${REPO}/releases/download/${VERSION}/${asset}"

    info "Detected platform: ${platform}"
    check_writable "$INSTALL_DIR"

    info "Downloading ${asset}..."

    # Explicit template for portability across BSD/GNU mktemp variants.
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/awx-cli.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT

    if ! curl -fsSL -o "${tmp}/${asset}" "$url"; then
        err "Failed to download from $url"
    fi

    info "Extracting..."
    if ! tar -xzf "${tmp}/${asset}" -C "$tmp"; then
        err "Failed to extract ${asset}"
    fi

    if [ ! -f "${tmp}/${BIN_NAME}" ]; then
        err "Archive did not contain expected '${BIN_NAME}' binary"
    fi

    chmod +x "${tmp}/${BIN_NAME}"

    # Strip macOS Gatekeeper quarantine attribute (silently ignored on Linux).
    if [ "$(uname -s)" = "Darwin" ]; then
        xattr -cr "${tmp}/${BIN_NAME}" 2>/dev/null || true
    fi

    mkdir -p "$INSTALL_DIR"
    mv "${tmp}/${BIN_NAME}" "${INSTALL_DIR}/${BIN_NAME}"

    info "Installed ${BIN_NAME} to ${INSTALL_DIR}/${BIN_NAME}"

    # --no-telemetry keeps the version check fast and avoids holding open a
    # network handle when stdout is captured by command substitution.
    installed_version=$("${INSTALL_DIR}/${BIN_NAME}" --no-telemetry --version 2>/dev/null || echo "unknown")
    info "Version: ${installed_version}"

    case ":$PATH:" in
        *":${INSTALL_DIR}:"*)
            info "Run '${BIN_NAME} --help' to get started."
            ;;
        *)
            rc_file=$(suggest_rc_file)
            warn "${INSTALL_DIR} is not on your PATH."
            warn "Add it by appending the following to ${rc_file}:"
            warn ""
            warn "    export PATH=\"${INSTALL_DIR}:\$PATH\""
            warn ""
            warn "Or run the binary directly: ${INSTALL_DIR}/${BIN_NAME} --help"
            ;;
    esac
}

main "$@"
