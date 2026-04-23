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

Auto-detects your OS and architecture, installs to `~/.local/bin/airwallex`:

```sh
curl -fsSL https://raw.githubusercontent.com/awx-cyrus-pastelero/airwallex-cli/main/install.sh | sh
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
- `beneficiaries`, `beneficiary-schema` — manage payout beneficiaries
- `billing-customers`, `billing-checkouts`, `billing-transactions` — billing
- `cards`, `cardholders`, `issuing-transactions` — issuing
- `conversions`, `conversion-amendments`, `conversion-rates`, `quotes` — FX
- `invoices`, `credit-notes`, `coupons`, `prices`, `products`, `subscriptions`, `meters`, `usage-events` — billing & catalog
- `payment-intents`, `payment-links`, `payment-disputes`, `payment-sources`, `payment-customers`, `refunds` — payments
- `transfers`, `global-accounts` — money movement
- `spend-bills`, `spend-expenses`, `spend-purchase-orders`, `spend-vendors`, `reimbursement-reports`, `financial-reports` — spend & finance
- `search-docs` — search the Airwallex API docs
- `feedback` — report issues or suggestions

## Documentation

For a full reference, see the [Airwallex API docs](https://www.airwallex.com/docs/api).

## Feedback

Got feedback? Open an issue or run `airwallex feedback`.

## License

Copyright (c) 2020-present, Airwallex, Inc.

Licensed under the [MIT License](LICENSE).
