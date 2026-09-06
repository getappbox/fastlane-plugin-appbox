#!/bin/bash
#
# Exercises the plugin against the bundled demo app.
#
# The demo project ships a prebuilt AppBox-Fastlane-Demo.ipa, so this drives the
# `appbox` action directly rather than running `gym` — no Xcode build, no signing
# certificates, no provisioning profile needed.
#
# Usage:
#   scripts/test-with-demo.sh                 preflight checks only (no upload)
#   scripts/test-with-demo.sh --upload        …then really upload to your Dropbox
#   scripts/test-with-demo.sh --upload --emails you@example.com
#   scripts/test-with-demo.sh --upload --keep-same-link
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO="$ROOT/AppBox-Fastlane-Demo-Project"
IPA="$DEMO/AppBox-Fastlane-Demo.ipa"
SHARE_FILE="$HOME/.appbox_share_value.json"

UPLOAD=0
EMAILS=""
KEEP_SAME_LINK=0
MESSAGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --upload) UPLOAD=1 ;;
    --emails) EMAILS="${2:?--emails needs an address}"; shift ;;
    --message) MESSAGE="${2:?--message needs text}"; shift ;;
    --keep-same-link) KEEP_SAME_LINK=1 ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAILED=1; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
step() { printf '\n\033[34m==>\033[0m %s\n' "$1"; }
FAILED=0

step "Preflight"

# 1. The plugin's own sources must at least parse.
if ruby -c "$ROOT/lib/fastlane/plugin/appbox/actions/appbox_action.rb" >/dev/null 2>&1; then
  pass "plugin action parses"
else
  fail "plugin action has a syntax error"
fi

# 2. The demo IPA the test uploads.
if [ -f "$IPA" ] && unzip -tqq "$IPA" >/dev/null 2>&1; then
  pass "demo IPA present and readable ($(du -h "$IPA" | cut -f1))"
else
  fail "demo IPA missing or corrupt: $IPA"
fi

# 3. AppBox.app — the CLI shells out to it for the upload.
if [ -d "/Applications/AppBox.app" ]; then
  version=$(defaults read /Applications/AppBox.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo "?")
  pass "AppBox.app installed (version $version)"
else
  fail "AppBox.app not in /Applications — install it from https://getappbox.com/download"
fi

# 4. The CLI itself, which the plugin invokes by name.
if CLI="$(command -v appboxcli)"; then
  pass "appboxcli on PATH ($CLI)"
else
  fail "appboxcli not found — install it from AppBox Preferences > General"
fi

# 5. Dropbox session. The CLI and the app share one, so this is the real gate on
#    whether an upload can succeed.
if command -v appboxcli >/dev/null 2>&1; then
  if account=$(appboxcli whoami 2>&1) && [ -n "$account" ]; then
    pass "Dropbox linked — $(echo "$account" | head -1)"
  else
    fail "not logged in to Dropbox — run: appboxcli login"
  fi
fi

# 6. fastlane, used to drive the action the way a real lane would.
if command -v fastlane >/dev/null 2>&1 || (cd "$DEMO" && bundle exec fastlane --version >/dev/null 2>&1); then
  pass "fastlane available"
else
  warn "fastlane not found — install with: gem install fastlane (or bundle install in the demo project)"
fi

if [ "$FAILED" -ne 0 ]; then
  printf '\n\033[31mPreflight failed.\033[0m Fix the items above and re-run.\n\n'
  exit 1
fi

if [ "$UPLOAD" -eq 0 ]; then
  printf '\n\033[32mPreflight passed.\033[0m Re-run with --upload to actually upload the demo IPA.\n'
  printf 'That uploads to your real Dropbox and, with --emails, sends a real email.\n\n'
  exit 0
fi

step "Uploading the demo IPA through the plugin"

# A throwaway lane that skips gym by pointing lane_context at the prebuilt IPA,
# then calls the action exactly as a user's Fastfile would.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/fastlane"

{
  # Load the plugin straight from this checkout.
  echo "require '$ROOT/lib/fastlane/plugin/appbox'"
  echo
  echo "default_platform(:ios)"
  echo
  echo "platform :ios do"
  echo "  desc 'Upload the prebuilt demo IPA through the appbox action'"
  echo "  lane :demo do"
  echo "    Actions.lane_context[Actions::SharedValues::IPA_OUTPUT_PATH] = '$IPA'"
  echo "    appbox("
  [ -n "$EMAILS" ]            && echo "      emails: '$EMAILS',"
  [ -n "$MESSAGE" ]           && echo "      message: '$MESSAGE',"
  [ "$KEEP_SAME_LINK" -eq 1 ] && echo "      keep_same_link: true,"
  echo "    )"
  echo "    UI.success(\"APPBOX_SHARE_URL    = #{Actions.lane_context[Actions::SharedValues::APPBOX_SHARE_URL]}\")"
  echo "    UI.success(\"APPBOX_IPA_URL      = #{Actions.lane_context[Actions::SharedValues::APPBOX_IPA_URL]}\")"
  echo "    UI.success(\"APPBOX_MANIFEST_URL = #{Actions.lane_context[Actions::SharedValues::APPBOX_MANIFEST_URL]}\")"
  echo "  end"
  echo "end"
} > "$WORK/fastlane/Fastfile"

rm -f "$SHARE_FILE"
(cd "$WORK" && FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_HIDE_CHANGELOG=1 fastlane demo)
STATUS=$?

step "Result"
if [ "$STATUS" -ne 0 ]; then
  fail "the lane failed (exit $STATUS)"
  exit 1
fi
pass "lane completed"

# The action reads these back out of the share file; check the contract held.
if [ -f "$SHARE_FILE" ]; then
  pass "share file written: $SHARE_FILE"
  for key in APPBOX_SHARE_URL APPBOX_IPA_URL APPBOX_MANIFEST_URL; do
    value=$(python3 -c "import json,sys;print(json.load(open('$SHARE_FILE')).get('$key',''))" 2>/dev/null)
    if [ -n "$value" ]; then pass "$key = $value"; else warn "$key is empty"; fi
  done
else
  fail "no $SHARE_FILE — the plugin cannot export APPBOX_* values without it"
  exit 1
fi

printf '\n\033[32mDone.\033[0m Open the share URL above on an iOS device to install the demo app.\n\n'
