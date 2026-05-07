# Release Automation

This repo uses Fastlane as a thin wrapper around the existing Flutter, Rust, and
shell build scripts.

## Current Scope

The first release automation layer is build-only:

- validates that `pubspec.yaml` has a release version with a build number
- optionally validates that a git tag matches the pubspec version
- builds staging Android split APKs and AAB for `org.parres.whitenoise.staging`
- builds production Android split APKs and AAB for `org.parres.whitenoise`
- builds staging iOS IPA for `dev.ipf.whitenoise.staging`
- builds production iOS IPA for `org.parres.whitenoise`
- stages artifacts under `build/releases/v<version>+<build>/<flavor>/`
- creates `.sha256` sidecar files for staged Android APK and AAB artifacts

Staging and production are separate apps on both Android and iOS. Current iOS
publishing target for both apps is App Store Connect/TestFlight. Store release
submission, GitHub Releases, Zap Store, and Play Store upload lanes will be added
after signing and account setup are stable.

Current app IDs:

- Production Android: `org.parres.whitenoise`
- Production iOS: `org.parres.whitenoise`
- Staging Android: `org.parres.whitenoise.staging`
- Staging iOS: `dev.ipf.whitenoise.staging`

If production moves under the IPF namespace later, the expected target would be
`dev.ipf.whitenoise` for production and `dev.ipf.whitenoise.staging` for staging
on both platforms.

## Setup

Install the Fastlane bundle:

```bash
bundle install
```

## Manual Release Runbook

The current release flow is local build automation plus manual uploads.

Set the release version:

```bash
export RELEASE_VERSION=2026.4.28
export RELEASE_BUILD=23
export RELEASE_TAG=v2026.4.28+23
```

1. Update `pubspec.yaml`.

   ```yaml
   version: 2026.4.28+23
   ```

   Then refresh Flutter dependencies so the Widgetbook path dependency records
   the same app version in `widgetbook/pubspec.lock`.

   ```bash
   just deps-flutter
   ```

2. Update `CHANGELOG.md`.

   Move the current `Unreleased` content into a dated release section and add a
   fresh `Unreleased` section above it:

   ```md
   ## Unreleased

   ### Added

   ### Changed

   ### Deprecated

   ### Removed

   ### Fixed

   ### Security

   ## [2026.4.28] - 2026-04-28
   ```

3. Run the pre-release checks.

   ```bash
   just precommit-check
   just test-release-scripts
   just release-doctor
   ```

4. Commit the release prep.

   ```bash
   git add pubspec.yaml widgetbook/pubspec.lock CHANGELOG.md RELEASE.md
   git commit -m "chore: prepare ${RELEASE_TAG}"
   ```

5. Create the annotated tag on the release commit.

   ```bash
   git tag -a "${RELEASE_TAG}" -m "Release ${RELEASE_TAG}"
   ```

6. Validate the tag guard.

   ```bash
   just release-doctor "${RELEASE_TAG}"
   ```

   This fails unless `pubspec.yaml` matches the tag, the tag exists, and the tag
   points at the current `HEAD`.

7. Build staging and production artifacts.

   ```bash
   just release-build-all "${RELEASE_TAG}"
   ```

   Release artifacts are staged under:

   ```text
   build/releases/v2026.4.28+23/staging/android/
   build/releases/v2026.4.28+23/staging/ios/
   build/releases/v2026.4.28+23/production/android/
   build/releases/v2026.4.28+23/production/ios/
   ```

8. Upload artifacts manually.

   Current upload targets:

   - GitHub Release: production APKs
   - Zap Store: production arm64 APK selected by `zapstore.yaml`
   - App Store Connect/TestFlight: staging IPA and production IPA
   - Play Store: production AAB after Play setup is complete
   - Play Store staging app: staging AAB after Play setup is complete

9. Push the release commit and tag after the build is verified.

   ```bash
   git push origin HEAD
   git push origin "${RELEASE_TAG}"
   ```

## Commands

Validate the current release version:

```bash
just release-doctor
```

Validate the current release version against a tag that exists on `HEAD`:

```bash
just release-doctor v2026.3.23+22
```

When a tag is passed, the validator requires all of these to be true:

- `pubspec.yaml` contains `version: 2026.3.23+22`
- the tag name is `v2026.3.23+22`
- the tag exists in git
- the tag points at the current `HEAD`

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
just release-build-all v2026.3.23+22
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
