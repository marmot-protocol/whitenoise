# White Noise

![White Noise](https://blossom.primal.net/3c36c07202823ff2f84072b94e9dd59896add1ceaaedb464fa639f988a6d8d1e.png)

A private, decentralized messenger built on [Nostr](https://github.com/nostr-protocol/nostr) using the [Marmot protocol](https://github.com/marmot-protocol/marmot) for MLS group encryption, with identity based on keypairs. Phone and email play no role in the system.

> This is the Flutter app. The core messaging library and CLI live in [whitenoise-rs](https://github.com/marmot-protocol/whitenoise-rs).

## What it does

**Encrypted group messaging.** White Noise uses MLS (Messaging Layer Security) for group chats, with forward secrecy and post-compromise security built in.

**Keypair identity.** Accounts are keypairs. Create one in the app or import your own. Phone numbers and email addresses play no part in this.

**Decentralized transport.** Messages route through Nostr relays. The architecture is serverless by design: any relay can carry your messages.

**External signer support.** Works with Amber and other NIP-55 signers. Your private key stays out of the app entirely.

**Media.** Send images and video with blurhash previews while loading. Attachments are encrypted at rest on device.

**Search and conversation management.** Find messages across all groups from a single search. Block or mute contacts, or archive entire chats.

**Multi-account with encrypted local storage.** Switch identities freely. App data is encrypted on device, and the local database migrates automatically on upgrade.

**Open source.** Released under the [AGPL-3.0 license](LICENSE).

## Supported Platforms

| Platform | Status    |
|----------|-----------|
| Android  | Supported |
| iOS      | Supported |
| macOS    | Planned   |
| Windows  | Planned   |
| Linux    | Planned   |
| Web      | Planned   |

## Stack

| Layer    | Technology |
|----------|------------|
| UI       | [Flutter](https://docs.flutter.dev/) (>=3.41.4) |
| Core     | Rust via [whitenoise-rs](https://github.com/marmot-protocol/whitenoise-rs) |
| FFI      | [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) |
| Protocol | [Marmot](https://github.com/marmot-protocol/marmot) (MLS over Nostr) |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.41.4 or later)
- [Rust](https://rustup.rs/) (latest stable)
- [Just](https://github.com/casey/just): `cargo install just`
- `flutter_rust_bridge_codegen`: `cargo install flutter_rust_bridge_codegen`

## Getting Started

```sh
just deps    # Install Flutter and Rust dependencies
just run     # Run on a connected device (staging flavor)
```

## Structure

```
lib/
├── constants/   # Fixed, shared values
├── providers/   # Shared app state (Riverpod)
├── hooks/       # Ephemeral widget state
├── services/    # Stateless operations
├── screens/     # Full-page components
└── widgets/     # Reusable components
```

The `rust/` directory holds a thin Rust crate that wraps [whitenoise-rs](https://github.com/marmot-protocol/whitenoise-rs) and generates the Flutter bridge bindings.

## Commands

```sh
just deps              # Install Flutter and Rust dependencies
just run               # Run on a connected device (staging)
just format            # Format Rust and Dart code
just lint              # Run Rust clippy and Flutter analyzer
just test-flutter      # Run Flutter tests
just test-rust         # Run Rust tests
just precommit         # Full pre-commit check (format, lint, test)
just coverage          # Check test coverage (minimum 99%)
just build-android     # Build Android APK
just build-ios         # Build Rust libs for iOS
```

Run `just` with no arguments to see all available commands.

## iOS Device Testing

For APNS, notification service extension, or release-signing validation on a
physical iOS device, build the flavor with `flutter build ios` and install the
built app bundle with `xcrun devicectl`. Avoid `flutter install` for these
checks because it may uninstall the existing app and delete the local database.
See [AGENTS.md](AGENTS.md#ios-device-installs) for the exact staging flow.

## Development Philosophy

- Keep complexity low. Keep the app thin.
- The whitenoise-rs crate is the source of truth. Avoid caching in Flutter.
- Shared app state goes in providers. Ephemeral widget state goes in hooks.
- Screens watch providers and pass data down to hooks.
- Test coverage must stay at 99% or above.
- Delete dead code. Commented code is dead code.
- Write self-explanatory code. Comments are for the non-obvious.

## Widgetbook

The repo includes a [Widgetbook](https://www.widgetbook.io/) for developing and reviewing UI components in isolation.

```sh
just widgetbook-macos   # Run on macOS
just widgetbook-linux   # Run on Linux
```

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a PR. The short version: fork the repo, open or comment on an issue before building significant features, keep PRs under ~500 lines, always run `just precommit`, and include screenshots for UI changes.

## Releases

See the [releases page](https://github.com/marmot-protocol/whitenoise/releases) for changelogs and APK downloads.

## Resources

- [Marmot protocol spec](https://github.com/marmot-protocol/marmot)
- [whitenoise-rs](https://github.com/marmot-protocol/whitenoise-rs): Rust core library and CLI
- [Flutter docs](https://docs.flutter.dev/)
- [whitenoise.chat](https://whitenoise.chat)

## License

White Noise is free and open source software, released under the [AGPL-3.0 license](LICENSE).
