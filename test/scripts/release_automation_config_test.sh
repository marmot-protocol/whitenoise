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
assert_contains "$android_gradle" '[[:space:]]*manifestPlaceholders\["deepLinkScheme"\] = "whitenoise-staging"'
assert_contains "$android_gradle" '[[:space:]]*manifestPlaceholders\["deepLinkScheme"\] = "whitenoise"'

android_manifest="$(cat android/app/src/main/AndroidManifest.xml)"
assert_contains "$android_manifest" '[[:space:]]*<data android:scheme="\$\{deepLinkScheme\}"/>'

ios_info="$(cat ios/Runner/Info.plist)"
assert_contains "$ios_info" '[[:space:]]*<key>CFBundleURLTypes</key>'
assert_contains "$ios_info" '[[:space:]]*<string>\$\(DEEPLINK_SCHEME\)</string>'

ios_project="$(cat ios/Runner.xcodeproj/project.pbxproj)"
assert_contains "$ios_project" '[[:space:]]*DEEPLINK_SCHEME = "whitenoise";'
assert_contains "$ios_project" '[[:space:]]*DEEPLINK_SCHEME = "whitenoise-staging";'

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

ruby <<'RUBY'
require 'digest'
require 'fileutils'
require 'tmpdir'

def opt_out_usage; end
def desc(_text); end
def lane(_name); end

module UI
  def self.user_error!(message)
    raise message
  end

  def self.important(_message); end
  def self.message(_message); end
end

load 'fastlane/Fastfile'

def release_info(_options = {})
  {
    'full_version' => '2026.5.7+24',
    'version_name' => '2026.5.7',
    'build_number' => '24',
  }
end

def run_from_root(_parts); end

def assert_sidecar_matches(artifact_path)
  checksum_path = "#{artifact_path}.sha256"
  raise "missing checksum sidecar for #{artifact_path}" unless File.file?(checksum_path)

  expected_digest = Digest::SHA256.file(artifact_path).hexdigest
  expected_contents = "#{expected_digest}  #{File.basename(artifact_path)}\n"
  actual_contents = File.read(checksum_path)

  raise "unexpected checksum contents: #{actual_contents.inspect}" unless actual_contents == expected_contents
end

Dir.mktmpdir do |dir|
  Object.send(:remove_const, :ROOT)
  Object.const_set(:ROOT, dir)

  apk_dir = File.join(ROOT, 'build', 'app', 'outputs', 'flutter-apk')
  aab_dir = File.join(ROOT, 'build', 'app', 'outputs', 'bundle', 'productionRelease')
  FileUtils.mkdir_p(apk_dir)
  FileUtils.mkdir_p(aab_dir)

  File.write(File.join(apk_dir, 'app-arm64-v8a-production-release.apk'), 'arm64 apk bytes')
  File.write(File.join(apk_dir, 'app-x86_64-production-release.apk'), 'x86 apk bytes')
  File.write(File.join(aab_dir, 'app-production-release.aab'), 'aab bytes')

  build_android_flavor('production', {}, build_native: true)

  output_dir = File.join(ROOT, 'build', 'releases', 'v2026.5.7+24', 'production', 'android')
  [
    'whitenoise-2026.5.7-arm64-v8a.apk',
    'whitenoise-2026.5.7-x86_64.apk',
    'whitenoise-2026.5.7.aab',
  ].each do |artifact_name|
    artifact_path = File.join(output_dir, artifact_name)
    raise "missing staged artifact #{artifact_path}" unless File.file?(artifact_path)

    assert_sidecar_matches(artifact_path)
  end
end
RUBY

echo "release_automation_config_test passed"
