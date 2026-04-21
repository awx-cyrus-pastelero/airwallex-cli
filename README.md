# Airwallex CLI

![GitHub release (latest by date)](https://img.shields.io/github/v/release/awx-cyrus-pastelero/airwallex-cli)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

The Airwallex CLI helps you build, test, and manage your Airwallex integration right from the terminal.

**With the CLI, you can:**

- Inspect balances, beneficiaries, transfers, and conversions
- Create and manage billing customers, products, prices, and subscriptions
- Issue cards, manage cardholders, and tail issuing transactions
- Search the Airwallex docs without leaving your shell

## Installation

Airwallex CLI is available for macOS and Linux as a single self-contained binary — no Python, pip, or runtime needed.

### macOS

```sh
curl -fL -o airwallex \
  https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest/download/airwallex-darwin-arm64
chmod +x airwallex && xattr -cr airwallex
sudo mv airwallex /usr/local/bin/
```

For Intel Macs, replace `airwallex-darwin-arm64` with `airwallex-darwin-amd64`.

### Linux

```sh
curl -fL -o airwallex \
  https://github.com/awx-cyrus-pastelero/airwallex-cli/releases/latest/download/airwallex-linux-amd64
chmod +x airwallex
sudo mv airwallex /usr/local/bin/
```

For arm64 hosts (AWS Graviton, Raspberry Pi), use `airwallex-linux-arm64`.

### Without `sudo`

```sh
mkdir -p ~/.local/bin && mv airwallex ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

## Usage

```sh
airwallex [command]

# Run `--help` for detailed information about CLI commands
airwallex [command] --help
```

## Commands

- `auth` — sign in and inspect the current session
- `balances` — view balance activity and totals
- `beneficiaries` — view and manage payout beneficiaries
- `billing-customers`, `billing-checkouts`, `billing-transactions` — billing
- `cards`, `cardholders`, `issuing-transactions` — issuing
- `conversions`, `quotes` — FX
- `invoices`, `credit-notes`, `coupons`, `prices`, `products`, `subscriptions`, `meters`, `usage-events` — billing & catalog
- `payment-links`, `payment-disputes`, `payment-sources`, `pa-customers`, `refunds` — payments
- `transfers`, `global-accounts` — money movement
- `spend-bills`, `financial-reports` — spend
- `search-docs` — search the Airwallex API docs
- `feedback` — report issues or suggestions

## Documentation

For a full reference, see the [Airwallex API docs](https://www.airwallex.com/docs/api).

## Feedback

Got feedback? Open an issue or run `airwallex feedback`.

## License

Copyright (c) 2020-present, Airwallex, Inc.

Licensed under the [MIT License](LICENSE).
