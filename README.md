# White Noise

![White Noise](https://blossom.primal.net/3c36c07202823ff2f84072b94e9dd59896add1ceaaedb464fa639f988a6d8d1e.png)

A secure, private, and decentralized chat app using the [marmot protocol 🦫](https://github.com/marmot-protocol/marmot) to build secure messaging with MLS and Nostr

## 📱 Supported Platforms

![Supported Platforms](https://blossom.primal.net/f03868727daf86f5d7d28d0e1286595381195f2d5e11b67c0d07e0b6fd8643fe.png)

- ✅ **Android** - Fully supported
- ✅ **iOS** - Fully supported
- ⏳ **macOS** - Not supported yet
- ⏳ **Windows** - Not supported yet
- ⏳ **Linux** - Not supported yet
- ⏳ **Web** - Not supported yet

## Structure

![Structure](https://blossom.primal.net/5d7e0ee655d45321c7b9c245bea50b1197e63baf33d10fd1fc708320f5b12ceb.png)

```
lib/
├── constants/     # Shared constants: fixed, related sets or reused elsewhere only
├── providers/     # Shared state
├── hooks/         # Ephemeral widget state
├── services/      # Stateless operations (API calls)
├── screens/       # Full-page components
├── widgets/       # Reusable components
```



## 🏗️ Stack

![Stack](https://blossom.primal.net/ac2b5cd3a7300114a4ddf3e9fa46850ae31a48e60bcba26b7c6e3f6774214dc1.png)

- [Flutter](https://docs.flutter.dev/)
- Rust
- flutter_rust_bridge - Dart ↔ Rust integration
- [whitenoise rust crate 🦀](https://github.com/marmot-protocol/whitenoise-rs)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.x or later)
- [Rust](https://rustup.rs/) (latest stable)
- [Just](https://github.com/casey/just) - `cargo install just`
- flutter_rust_bridge_codegen - `cargo install flutter_rust_bridge_codegen`


## 🛠️ Commands

![Commands](https://blossom.primal.net/e64f261507f6bcf1ca986fc0c38998e18ea02b7d8dbfd57bf43873b139645c58.png)

```bash
# Install dependencies
just deps              # Install both Flutter and Rust deps
just deps-flutter      # Flutter dependencies only
just deps-rust         # Rust dependencies only

# Format code
just format            # Format both Rust and Dart
just format-rust       # Format Rust only
just format-dart       # Format Dart only

# Coverage
just coverage          # Checks tests coverage
```

### Coverage Report

You need to install lcov to generate report
```bash
# Mac OS
brew install lcov

# Linux
apt-get install lcov
```

```bash
# First run tests with coverage option
flutter test --coverage
# Generate coverage html report
genhtml coverage/lcov.info -o coverage/html 
# Open coverage/html/index.html in your browser
```


## Development philosophy

![Development Philosophy](https://blossom.primal.net/edcfec3e6e04cb1ddde6198a9494cf9a3ae19b6b994ce11e444af1f9b8ca4502.png)

- We keep complexity low.
- We keep the app thin.
- We test our code.
- We delete dead code. Commented code is dead code.
- We use the Whitenoise Rust crate as the source of truth.
- We avoid caching in Flutter; the Whitenoise crate already persists data in a local DB.
- We put shared app state in providers.
- We put ephemeral widget state in hooks.
- We pass data to hooks, not widget refs.
- We let screens watch providers and pass data to hooks.
- We avoid comments unless strictly necessary and write self-explanatory code.

## 📚 Resources

![Resources](https://blossom.primal.net/04a82bb37c8270cc4b13f26c8f3d904fee3624c9eaa6aaa96c489003129ecd21.png)

- [Flutter Docs](https://docs.flutter.dev/)
- [White Noise Rust crate](https://github.com/marmot-protocol/whitenoise-rs)
- [White Noise Flutter](https://github.com/marmot-protocol/whitenoise)
