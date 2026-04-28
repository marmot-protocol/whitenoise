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
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain '$needle'"
  fi
}

just_list="$(just --list --unsorted)"
assert_contains "$just_list" "release-build-staging"
assert_contains "$just_list" "release-build-production"
assert_contains "$just_list" "release-build-android-staging"
assert_contains "$just_list" "release-build-android-production"

fastfile="$(cat fastlane/Fastfile)"
assert_contains "$fastfile" "lane :build_android_staging"
assert_contains "$fastfile" "lane :build_android_production"
assert_contains "$fastfile" "lane :build_staging_release"
assert_contains "$fastfile" "lane :build_production_release"
assert_contains "$fastfile" "android_package_name: 'dev.ipf.whitenoise.staging'"
assert_contains "$fastfile" "android_package_name: 'org.parres.whitenoise'"
assert_contains "$fastfile" "ios_app_identifier: 'dev.ipf.whitenoise.staging'"
assert_contains "$fastfile" "ios_app_identifier: 'org.parres.whitenoise'"

android_gradle="$(cat android/app/build.gradle.kts)"
assert_contains "$android_gradle" 'applicationId = "dev.ipf.whitenoise.staging"'
assert_contains "$android_gradle" 'applicationId = "org.parres.whitenoise"'

ruby <<'RUBY'
require 'yaml'

pattern = YAML.load_file('zapstore.yaml').fetch('match')
regex = Regexp.new(pattern)

production_apk = 'whitenoise-2026.3.23-arm64-v8a.apk'
staging_apk = 'whitenoise-staging-2026.3.23-arm64-v8a.apk'

raise 'Zap Store match must include production arm64 APK' unless regex.match?(production_apk)
raise 'Zap Store match must exclude staging APK' if regex.match?(staging_apk)
RUBY

echo "release_automation_config_test passed"
