#!/bin/sh
# Airwallex CLI installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/awx-cyrus-pastelero/airwallex-cli/main/install.sh | sh
#
# Environment variables:
#   AIRWALLEX_VERSION       pin a specific release (default: latest, e.g. v0.1.0)
#   AIRWALLEX_INSTALL_DIR   install location (default: $HOME/.local/bin)

set -eu

REPO="awx-cyrus-pastelero/airwallex-cli"
BIN_NAME="airwallex"
INSTALL_DIR="${AIRWALLEX_INSTALL_DIR:-$HOME/.local/bin}"
STATE_DIR="${HOME}/.local/share/airwallex"
VERSION="${AIRWALLEX_VERSION:-latest}"

# Colors via terminfo so we get real ESC bytes (not literal '\033[…]').
# `tput setaf` is universally available on POSIX systems and respects
# $TERM. Falls back to empty strings when stdout isn't a tty (CI, log
# files) or terminfo doesn't know how to colour the current terminal.
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD=$(tput bold)
    DIM=$(tput dim)
    BLUE=$(tput setaf 4)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    RESET=$(tput sgr0)
else
    BOLD=''
    DIM=''
    BLUE=''
    GREEN=''
    YELLOW=''
    RED=''
    RESET=''
fi

# Output helpers. Glyphs are UTF-8; modern macOS / Linux terminals all
# render these correctly. Reserve plain ASCII fallbacks for the rare
# legacy terminal: '*' for step, '+' for ok, '!' for warn, 'x' for err.
if [ "${LANG:-}" != "${LANG#*UTF-8}" ] || [ "${LC_ALL:-}" != "${LC_ALL#*UTF-8}" ]; then
    G_STEP='→'
    G_OK='✓'
    G_WARN='!'
    G_ERR='✗'
else
    G_STEP='*'
    G_OK='+'
    G_WARN='!'
    G_ERR='x'
fi

# Output levels:
#   header(): one-time banner at the top
#   step():   a unit of progress (blue arrow)
#   ok():     a success summary line (green check)
#   warn():   non-fatal warning (yellow bang)
#   err():    fatal error (red x), exits 1
header() { printf '\n%s%sairwallex CLI installer%s\n\n' "$BOLD" "$BLUE" "$RESET"; }
step()   { printf '  %s%s%s %s\n' "$BLUE"   "$G_STEP" "$RESET" "$*"; }
ok()     { printf '  %s%s%s %s\n' "$GREEN"  "$G_OK"   "$RESET" "$*"; }
warn()   { printf '  %s%s%s %s\n' "$YELLOW" "$G_WARN" "$RESET" "$*" >&2; }
err()    { printf '\n  %s%s%s %s\n\n' "$RED" "$G_ERR" "$RESET" "$*" >&2; exit 1; }

# Detect the platform and emit the asset-name fragment used in release
# filenames. We deliberately use `mac-os` / `x86_64` rather than
# `darwin` / `amd64` so the asset names match every other major CLI's
# convention — installer scripts and package mirrors slot in without a
# custom URL template.
detect_platform() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "$os" in
        darwin) os_label="darwin" ;;
        linux)  os_label="linux" ;;
        *)      err "Unsupported OS: $os (supported: darwin, linux)" ;;
    esac

    case "$arch" in
        x86_64|amd64)   arch_label="amd64" ;;
        arm64|aarch64)  arch_label="arm64" ;;
        *) err "Unsupported architecture: $arch (supported: x86_64, arm64)" ;;
    esac

    echo "${os_label}-${arch_label}"
}

# Return the absolute path to the shell rc file for PATH configuration.
resolve_rc_file() {
    case "${SHELL:-}" in
        */zsh)  echo "$HOME/.zshrc" ;;
        */bash) echo "$HOME/.bashrc" ;;
        */fish) echo "$HOME/.config/fish/config.fish" ;;
        *)      echo "" ;;
    esac
}

# Add INSTALL_DIR to PATH in the user's shell rc file if not already present.
ensure_path() {
    rc_file=$(resolve_rc_file)
    [ -z "$rc_file" ] && return 1

    if [ -f "$rc_file" ] && grep -qF "$INSTALL_DIR" "$rc_file" 2>/dev/null; then
        return 0
    fi

    mkdir -p "$(dirname "$rc_file")"

    case "${SHELL:-}" in
        */fish)
            printf '\nfish_add_path "%s"\n' "$INSTALL_DIR" >> "$rc_file"
            ;;
        *)
            printf '\nexport PATH="%s:$PATH"\n' "$INSTALL_DIR" >> "$rc_file"
            ;;
    esac
    return 0
}

# Pre-flight: make sure we can actually write to INSTALL_DIR before downloading
# anything. Fail fast with a useful message instead of cryptic mv permission errors.
check_writable() {
    dir="$1"
    if [ -d "$dir" ]; then
        if [ ! -w "$dir" ]; then
            err "$(printf '%s' "Cannot write to $dir.
    Re-run with sudo, or pick a writable location:
        AIRWALLEX_INSTALL_DIR=\$HOME/.local/bin curl -fsSL ... | sh")"
        fi
    else
        parent=$(dirname "$dir")
        if [ ! -w "$parent" ]; then
            err "$(printf '%s' "Cannot create $dir (parent $parent is not writable).
    Re-run with sudo, or pick a writable location:
        AIRWALLEX_INSTALL_DIR=\$HOME/.local/bin curl -fsSL ... | sh")"
        fi
    fi
}

# Resolve the latest release tag from the GitHub API. Kept even though
# raw-binary assets are unversioned and could use the
# /releases/latest/download/<asset> redirect — the installer still prints
# and records the resolved version for the user.
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

    header

    if [ "$VERSION" = "latest" ]; then
        VERSION=$(resolve_latest_version)
    fi
    step "Latest version: ${BOLD}${VERSION}${RESET}"

    # Strip a leading "v" for display/state purposes only; asset filenames
    # are not versioned (e.g. airwallex-darwin-arm64).
    version_no_v=${VERSION#v}

    platform=$(detect_platform)
    asset="${BIN_NAME}-${platform}"
    url="https://github.com/${REPO}/releases/download/${VERSION}/${asset}"

    check_writable "$INSTALL_DIR"

    step "Downloading ${asset}"

    # Explicit template for portability across BSD/GNU mktemp variants.
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/airwallex-cli.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT

    # Asset is a raw executable (no archive); download directly to BIN_NAME
    # so no extract step is needed.
    if ! curl -fsSL -o "${tmp}/${BIN_NAME}" "$url"; then
        err "Failed to download from $url"
    fi

    chmod +x "${tmp}/${BIN_NAME}"

    mkdir -p "$INSTALL_DIR"
    mv "${tmp}/${BIN_NAME}" "${INSTALL_DIR}/${BIN_NAME}"

    mkdir -p "$STATE_DIR"

    installed_version=$("${INSTALL_DIR}/${BIN_NAME}" --no-telemetry --version 2>/dev/null || echo "${version_no_v}")

    ok "Installed ${BOLD}${BIN_NAME} ${installed_version}${RESET} to ${DIM}${INSTALL_DIR}/${BIN_NAME}${RESET}"

    case ":$PATH:" in
        *":${INSTALL_DIR}:"*)
            ;;
        *)
            if ensure_path; then
                rc_file=$(resolve_rc_file)
                ok "Added ${BOLD}${INSTALL_DIR}${RESET} to ${BOLD}${rc_file}${RESET}"
                printf '\n  Restart your shell or run:\n        %ssource %s%s\n' \
                    "$DIM" "$rc_file" "$RESET"
            else
                printf '\n  %s%s%s %s%s%s is not on your PATH.\n' \
                    "$YELLOW" "$G_WARN" "$RESET" "$BOLD" "$INSTALL_DIR" "$RESET"
                printf '    Add it to your shell startup file:\n        %sexport PATH="%s:\$PATH"%s\n' \
                    "$DIM" "$INSTALL_DIR" "$RESET"
            fi
            ;;
    esac

    printf '\n  Run %s%s --help%s to get started.\n\n' "$BOLD" "$BIN_NAME" "$RESET"
}

main "$@"
