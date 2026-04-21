# airwallex CLI

A self-contained `airwallex` command-line tool for managing Airwallex APIs. Ships as a single native binary per platform — no Python, pip, or runtime needed on the target machine.

[![Latest Release](https://img.shields.io/github/v/release/awx-cyrus-pastelero/airwallex-cli?label=release)](https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Install

Pick whichever is easier. Both end up in the same place.

### Option A — manual download

1. Go to the [latest release](https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest) and download the file matching your machine:

    | Your machine                            | File                       |
    | --------------------------------------- | -------------------------- |
    | Mac M1/M2/M3/M4 (Apple Silicon)         | `airwallex-darwin-arm64`   |
    | Intel Mac (pre-2020)                    | `airwallex-darwin-amd64`   |
    | Linux x86_64                            | `airwallex-linux-amd64`    |
    | Linux arm64 (AWS Graviton, Pi, etc.)    | `airwallex-linux-arm64`    |

    Not sure which? Run `uname -sm`.

2. In Terminal (adjust filename for your platform):

    ```sh
    cd ~/Downloads
    xattr -cr airwallex-darwin-arm64     # macOS only — strips Gatekeeper quarantine
    chmod +x airwallex-darwin-arm64
    ./airwallex-darwin-arm64 --version   # → 0.1.0
    ```

### Option B — curl one-liner

No authentication needed — assets are public.

<details>
<summary><strong>macOS — Apple Silicon (M1/M2/M3/M4)</strong></summary>

```sh
curl -fL -o airwallex \
  https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest/download/airwallex-darwin-arm64
chmod +x airwallex && xattr -cr airwallex
./airwallex --version
```

</details>

<details>
<summary><strong>macOS — Intel</strong></summary>

```sh
curl -fL -o airwallex \
  https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest/download/airwallex-darwin-amd64
chmod +x airwallex && xattr -cr airwallex
./airwallex --version
```

</details>

<details>
<summary><strong>Linux — x86_64</strong></summary>

```sh
curl -fL -o airwallex \
  https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest/download/airwallex-linux-amd64
chmod +x airwallex
./airwallex --version
```

</details>

<details>
<summary><strong>Linux — arm64</strong></summary>

```sh
curl -fL -o airwallex \
  https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest/download/airwallex-linux-arm64
chmod +x airwallex
./airwallex --version
```

</details>

### Put it on your PATH

```sh
mkdir -p ~/.local/bin && mv airwallex ~/.local/bin/
# if ~/.local/bin isn't already on PATH:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
airwallex --help
```

---

## Try it out

```sh
airwallex --version                  # 0.1.0
airwallex --help                     # full usage
airwallex balances --help
airwallex invoices --help
airwallex credit-notes --help
airwallex auth whoami                # hits the Airwallex API
```

Every subcommand should print something. If one errors with `ModuleNotFoundError`, that's a packaging bug — please file an issue.

---

## Verify checksums (optional)

Each release ships a `.sha256` sidecar next to every binary. Compare locally:

```sh
# macOS
shasum -a 256 airwallex                    # compare with the .sha256 file from the release

# Linux
sha256sum airwallex
```

---

## Documentation

- API reference: <https://www.airwallex.com/docs/api>
- Developer hub: <https://www.airwallex.com/docs>

## License

MIT — see [LICENSE](LICENSE).
