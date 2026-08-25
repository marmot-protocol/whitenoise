# White Noise

A private, decentralized messenger built on [Nostr](https://github.com/nostr-protocol/nostr) and the [Marmot Protocol](https://github.com/marmot-protocol/marmot) for MLS-based end-to-end encrypted group messaging.

No phone. No email. No compromise.

> **Note:** This repository was the original Flutter codebase that targeted both iOS and Android. Development has moved to per-platform repositories; this repo is now the project landing page. New development happens in the platform repos linked below.

## Clients

| Platform | Repository | Stack | Status |
|----------|------------|-------|--------|
| Android | [`whitenoise-android`](https://github.com/marmot-protocol/whitenoise-android) | Kotlin · Jetpack Compose | In development |
| iOS | [`whitenoise-ios`](https://github.com/marmot-protocol/whitenoise-ios) | Swift · SwiftUI | In development |
| macOS | [`whitenoise-mac`](https://github.com/marmot-protocol/whitenoise-mac) | Swift · SwiftUI | In development |
| Linux | [`whitenoise-linux`](https://github.com/marmot-protocol/whitenoise-linux) | Rust · Slint | In development |
| Windows | — | — | Planned |
| Web | — | — | Planned |

## Protocol

White Noise speaks the [Marmot Protocol](https://github.com/marmot-protocol/marmot): MLS (Messaging Layer Security) carried over Nostr relays. The protocol specification is maintained in that repository, organized by protocol surface (foundation, protocol-core, app components, transports, features).

## Related projects

A curated list of apps, libraries, and tools built on the Marmot Protocol is maintained at [`awesome-marmot`](https://github.com/marmot-protocol/awesome-marmot).

For a curated map of relevant repositories in the Marmot Protocol organization, including SDKs, language bindings, and tooling, see [`REPOS.md`](REPOS.md). For the exhaustive inventory, see the [organization's repository list](https://github.com/orgs/marmot-protocol/repositories).

## License

Each client repository carries its own license. The legacy Flutter sources in this repository are released under the [AGPL-3.0 license](LICENSE).

---

*This repository previously held the White Noise Flutter app (iOS + Android). The complete Flutter codebase is preserved at the [`flutter-final`](https://github.com/marmot-protocol/whitenoise/tree/flutter-final) tag.*
