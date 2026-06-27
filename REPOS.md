# Marmot Protocol Repository Map

A map of every active repository in the `marmot-protocol` organization, intended for humans and coding agents navigating the project. For per-repo agent guidance specific to this Flutter codebase, see [`AGENTS.md`](AGENTS.md). For a one-page introduction to White Noise, see [`LANDING.md`](LANDING.md).

> **About this repository.** `marmot-protocol/whitenoise` originally held the cross-platform Flutter app for iOS and Android. Active client development has since moved to per-platform repositories. The Flutter sources remain on `master` for history and any in-flight work; this file points you to where current work happens.

## Quick routing

| If you want to... | Go to |
|---|---|
| File a bug or feature request for the Android client | [`whitenoise-android`](https://github.com/marmot-protocol/whitenoise-android) |
| File a bug or feature request for the iOS client | [`whitenoise-ios`](https://github.com/marmot-protocol/whitenoise-ios) |
| File a bug or feature request for the macOS client | [`whitenoise-mac`](https://github.com/marmot-protocol/whitenoise-mac) |
| File a bug or feature request for the Linux client | [`whitenoise-linux`](https://github.com/marmot-protocol/whitenoise-linux) |
| Read or propose changes to the Marmot Protocol spec | [`marmot`](https://github.com/marmot-protocol/marmot) |
| Build a client or tool on top of Marmot | [`mdk`](https://github.com/marmot-protocol/mdk) plus the language binding for your stack |
| Run a Marmot push-notifications server | [`transponder`](https://github.com/marmot-protocol/transponder) |
| Browse apps, libraries, and tools already built on Marmot | [`awesome-marmot`](https://github.com/marmot-protocol/awesome-marmot) |
| Install Marmot CLI tooling via Homebrew | [`homebrew-tap`](https://github.com/marmot-protocol/homebrew-tap) |

## Clients

End-user White Noise clients. Each repository owns its own build, release, and issue tracker.

| Repository | Platform | Language | UI toolkit | Notes |
|---|---|---|---|---|
| [`whitenoise-android`](https://github.com/marmot-protocol/whitenoise-android) | Android | Kotlin | Jetpack Compose | Build via `just`; production and staging signed APK flavors. |
| [`whitenoise-ios`](https://github.com/marmot-protocol/whitenoise-ios) | iOS | Swift | SwiftUI | Wraps a vendored UniFFI `MarmotKit` xcframework; includes a Notification Service Extension for privacy-preserving APNS wakes. |
| [`whitenoise-mac`](https://github.com/marmot-protocol/whitenoise-mac) | macOS 15.6+, Apple Silicon | Swift | SwiftUI | Sandboxed single-window app; consumes a vendored `MarmotKit` framework. |
| [`whitenoise-linux`](https://github.com/marmot-protocol/whitenoise-linux) | Linux x86-64, Linux ARM64 | Rust | Slint | Single Rust binary; encrypted vault file with Argon2id-derived key. |

## Protocol

| Repository | Purpose |
|---|---|
| [`marmot`](https://github.com/marmot-protocol/marmot) | The Marmot Protocol specification. Contains the MIP series defining MLS over Nostr group messaging, the Marmot Group Data Extension (`0xF2EE`), key package and welcome event kinds (`443`, `444`), group event kind (`445`), and the exporter-secret-based NIP-44 encryption scheme. |
| [`marmot-web`](https://github.com/marmot-protocol/marmot-web) | The Marmot Protocol website. |

## Marmot Development Kit (MDK)

The MDK is the recommended starting point for anyone building a Marmot client or tool. It provides a Rust core plus generated bindings for multiple languages.

| Repository | Language | Purpose |
|---|---|---|
| [`mdk`](https://github.com/marmot-protocol/mdk) | Rust | Core Marmot Development Kit. The source of truth for all language bindings. |
| [`mdk-swift`](https://github.com/marmot-protocol/mdk-swift) | Swift | UniFFI-generated Swift bindings. Default branch: `main`. |
| [`mdk-kotlin`](https://github.com/marmot-protocol/mdk-kotlin) | Kotlin | UniFFI-generated Kotlin and JNI bindings for Android and the JVM. |
| [`mdk-python`](https://github.com/marmot-protocol/mdk-python) | Python | UniFFI-generated Python bindings. Default branch: `main`. |
| [`mdk-ruby`](https://github.com/marmot-protocol/mdk-ruby) | Ruby | UniFFI-generated Ruby bindings. Default branch: `main`. |
| [`mdk-web`](https://github.com/marmot-protocol/mdk-web) | TypeScript / WASM | Browser-friendly MDK distribution. |
| [`mdk-python-example`](https://github.com/marmot-protocol/mdk-python-example) | Python | Reference example using `mdk-python`. Default branch: `main`. |
| [`mdk-kotlin-example`](https://github.com/marmot-protocol/mdk-kotlin-example) | Kotlin | Reference example using `mdk-kotlin`. |
| [`mdk-ruby-example`](https://github.com/marmot-protocol/mdk-ruby-example) | Ruby | Reference example using `mdk-ruby`. |

## TypeScript and Web implementations

For browser and Node.js builders who want a pure TypeScript path rather than a WASM-wrapped Rust core.

| Repository | Purpose |
|---|---|
| [`marmot-ts`](https://github.com/marmot-protocol/marmot-ts) | TypeScript implementation of the Marmot protocol. |
| [`marmots-web-chat`](https://github.com/marmot-protocol/marmots-web-chat) | Reference web-chat implementation built on `marmot-ts`. |

## Servers and infrastructure

| Repository | Purpose |
|---|---|
| [`transponder`](https://github.com/marmot-protocol/transponder) | MIP-05 Marmot notifications server, implemented in Rust. Run this if you operate push infrastructure for Marmot clients. |

## Storage adapters

OpenMLS storage backends. Useful if you are embedding OpenMLS in a client or service and need a persistence layer other than the default.

| Repository | Backend |
|---|---|
| [`openmls-sled-storage`](https://github.com/marmot-protocol/openmls-sled-storage) | Sled embedded database. |
| [`openmls-lmdb-storage`](https://github.com/marmot-protocol/openmls-lmdb-storage) | LMDB. |
| [`openmls-redb-storage`](https://github.com/marmot-protocol/openmls-redb-storage) | Redb embedded database. |

## Tooling and utilities

| Repository | Purpose |
|---|---|
| [`wn-tui`](https://github.com/marmot-protocol/wn-tui) | Terminal user interface for White Noise. Useful for headless testing and scripted interaction. |
| [`goggles`](https://github.com/marmot-protocol/goggles) | Visualization tooling for Marmot group state. Helpful when debugging group state or epoch transitions. |
| [`proton-beam`](https://github.com/marmot-protocol/proton-beam) | Converts Nostr events to Protobuf. Useful for analytics pipelines and offline processing. |
| [`homebrew-tap`](https://github.com/marmot-protocol/homebrew-tap) | Homebrew formulas for Marmot Protocol tools. Run `brew tap marmot-protocol/tap` to install. |

## Curated index

| Repository | Purpose |
|---|---|
| [`awesome-marmot`](https://github.com/marmot-protocol/awesome-marmot) | Curated list of apps, libraries, and tools built on the Marmot Protocol. Start here when surveying what exists before building something new. |

## Conventions agents should know

- **Default branch.** Most repositories default to `master`. The following use `main`: `mdk-swift`, `mdk-python`, `mdk-ruby`, `mdk-python-example`. Verify with `gh api repos/marmot-protocol/<repo> --jq .default_branch` before opening a PR.
- **Issue templates.** Client repositories use `[Bug]:` and `[Feature]:` title prefixes. Check each repo's `.github/ISSUE_TEMPLATE/` directory for the current schema before filing.
- **Protocol terminology.** The group encryption protocol is called **the Marmot Protocol**. Group encryption is Marmot end-to-end.
- **Spec changes.** Protocol-level changes belong as MIP proposals in [`marmot`](https://github.com/marmot-protocol/marmot), not as features in individual clients.
- **Scope.** Glue code that combines HTTPS and Nostr-relay traffic (for example, app-update checks against Zapstore) belongs in the client app repositories, not in the core MDK.

## What is intentionally not listed here

This file lists the repositories most relevant to building on or contributing to the Marmot Protocol and White Noise clients. Internal experiments, personal websites, media-asset archives, and unrelated tooling owned by organization members are not enumerated here even though they may exist in the organization. When in doubt, consult [`awesome-marmot`](https://github.com/marmot-protocol/awesome-marmot) or the organization's repository list.
