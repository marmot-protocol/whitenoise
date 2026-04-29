#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local pattern="$2"
  if ! printf '%s\n' "$haystack" | grep -Eq "^${pattern}$"; then
    fail "expected output to contain line matching regex '$pattern'"
  fi
}

just_list="$(just --list --unsorted)"
assert_contains "$just_list" '[[:space:]]*release-build-staging[[:space:]].*'
assert_contains "$just_list" '[[:space:]]*release-build-production[[:space:]].*'
assert_contains "$just_list" '[[:space:]]*release-build-android-staging[[:space:]].*'
assert_contains "$just_list" '[[:space:]]*release-build-android-production[[:space:]].*'
assert_contains "$just_list" '[[:space:]]*release-build-ios-staging[[:space:]].*'
assert_contains "$just_list" '[[:space:]]*release-build-ios-production[[:space:]].*'

fastfile="$(cat fastlane/Fastfile)"
assert_contains "$fastfile" 'lane[[:space:]]+:build_android_staging[[:space:]]+do.*'
assert_contains "$fastfile" 'lane[[:space:]]+:build_android_production[[:space:]]+do.*'
assert_contains "$fastfile" 'lane[[:space:]]+:build_ios_staging[[:space:]]+do.*'
assert_contains "$fastfile" 'lane[[:space:]]+:build_ios_production[[:space:]]+do.*'
assert_contains "$fastfile" 'lane[[:space:]]+:build_staging_release[[:space:]]+do.*'
assert_contains "$fastfile" 'lane[[:space:]]+:build_production_release[[:space:]]+do.*'
assert_contains "$fastfile" "[[:space:]]*android_package_name: 'org\\.parres\\.whitenoise\\.staging',"
assert_contains "$fastfile" "[[:space:]]*android_package_name: 'org\\.parres\\.whitenoise',"
assert_contains "$fastfile" "[[:space:]]*ios_app_identifier: 'dev\\.ipf\\.whitenoise\\.staging',"
assert_contains "$fastfile" "[[:space:]]*ios_app_identifier: 'org\\.parres\\.whitenoise',"

android_gradle="$(cat android/app/build.gradle.kts)"
assert_contains "$android_gradle" '[[:space:]]*applicationIdSuffix = "\.staging"'
assert_contains "$android_gradle" '[[:space:]]*applicationId = "org\.parres\.whitenoise"'

ruby <<'RUBY'
require 'yaml'

config = YAML.safe_load(
  File.read('zapstore.yaml'),
  permitted_classes: [],
  permitted_symbols: [],
  aliases: false,
)
pattern = config.fetch('match')
regex = Regexp.new(pattern)

production_apk = 'whitenoise-2026.3.23-arm64-v8a.apk'
staging_apk = 'whitenoise-staging-2026.3.23-arm64-v8a.apk'

raise 'Zap Store match must include production arm64 APK' unless regex.match?(production_apk)
raise 'Zap Store match must exclude staging APK' if regex.match?(staging_apk)
RUBY

echo "release_automation_config_test passed"
