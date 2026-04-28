# Release Automation

This repo uses Fastlane as a thin wrapper around the existing Flutter, Rust, and
shell build scripts.

## Current Scope

The first release automation layer is build-only:

- validates that `pubspec.yaml` has a release version with a build number
- optionally validates that a git tag matches the pubspec version
- builds staging Android split APKs and AAB for `dev.ipf.whitenoise.staging`
- builds production Android split APKs and AAB for `org.parres.whitenoise`
- builds staging iOS IPA for `dev.ipf.whitenoise.staging`
- builds production iOS IPA for `org.parres.whitenoise`
- stages artifacts under `build/releases/v<version>+<build>/<flavor>/`

Staging and production are separate apps on both Android and iOS. Current iOS
publishing target for both apps is App Store Connect/TestFlight. Store release
submission, GitHub Releases, Zap Store, and Play Store upload lanes will be added
after signing and account setup are stable.

Current app IDs:

- Production: `org.parres.whitenoise`
- Staging: `dev.ipf.whitenoise.staging`

If production moves under the IPF namespace later, the expected target would be
`dev.ipf.whitenoise` for production and `dev.ipf.whitenoise.staging` for staging.

## Setup

Install the Fastlane bundle:

```bash
bundle install
```

## Commands

Validate the current release version:

```bash
just release-doctor
```

Validate the current release version against a tag:

```bash
just release-doctor v2026.3.23+22
```

Build the staging app release artifacts:

```bash
just release-build-staging
```

Build the production app release artifacts:

```bash
just release-build-production
```

Build both staging and production app release artifacts:

```bash
just release-build-all
```

Build only staging Android artifacts:

```bash
just release-build-android-staging
```

Build only production Android artifacts:

```bash
just release-build-android-production
```

Build only staging iOS artifacts:

```bash
just release-build-ios-staging
```

Build only production iOS artifacts:

```bash
just release-build-ios-production
```

## Secrets

Do not commit store credentials, App Store Connect API keys, provisioning files,
or Android keystores. Fastlane local credential files such as `.p8` and `.json`
files under `fastlane/` are ignored by git.
