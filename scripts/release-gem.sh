#!/bin/bash
#
# Builds and publishes the fastlane-plugin-appbox gem to RubyGems.
#
# Usage:
#   scripts/release-gem.sh                     checks + build, no publish
#   scripts/release-gem.sh --version 4.0.1     set the version first
#   scripts/release-gem.sh --publish           …then push to RubyGems and tag
#   scripts/release-gem.sh --version 4.1.0 --publish
#   scripts/release-gem.sh --skip-tests
#
# Nothing is pushed without --publish. The git tag is created locally; pushing
# it is left to you.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

VERSION_FILE="lib/fastlane/plugin/appbox/version.rb"
GEM_NAME="fastlane-plugin-appbox"

NEW_VERSION=""
PUBLISH=0
SKIP_TESTS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --version) NEW_VERSION="${2:?--version needs a value like 4.0.1}"; shift ;;
    --publish) PUBLISH=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
step() { printf '\n\033[34m==>\033[0m %s\n' "$1"; }
die()  { printf '\n\033[31m✗ %s\033[0m\n\n' "$1"; exit 1; }

current_version() { ruby -r "./$VERSION_FILE" -e 'print Fastlane::Appbox::VERSION' 2>/dev/null; }

# ---------------------------------------------------------------- version
if [ -n "$NEW_VERSION" ]; then
  step "Setting version to $NEW_VERSION"
  echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+' || die "Not a valid version: $NEW_VERSION"
  /usr/bin/sed -i '' -E "s/VERSION = \".*\"/VERSION = \"$NEW_VERSION\"/" "$VERSION_FILE"
  pass "$VERSION_FILE updated"
fi

VERSION="$(current_version)"
[ -n "$VERSION" ] || die "Could not read the version from $VERSION_FILE"
step "Releasing $GEM_NAME $VERSION"

# ---------------------------------------------------------------- checks
if [ "$SKIP_TESTS" -eq 1 ]; then
  warn "skipping tests (--skip-tests)"
else
  step "Tests and lint"
  bundle exec rspec >/dev/null 2>&1 || die "rspec failed — run 'bundle exec rspec' to see why"
  pass "rspec"
  bundle exec rubocop >/dev/null 2>&1 || warn "rubocop reported offences (not blocking)"
  pass "rubocop run"
fi

step "Sanity checks"

# The action has to at least parse, or the gem is dead on arrival.
ruby -c lib/fastlane/plugin/appbox/actions/appbox_action.rb >/dev/null 2>&1 \
  || die "lib/.../appbox_action.rb has a syntax error"
pass "sources parse"

# Publishing the same version twice is rejected by RubyGems; catch it early.
PUBLISHED=$(curl -fsS "https://rubygems.org/api/v1/versions/$GEM_NAME.json" 2>/dev/null \
  | ruby -rjson -e 'puts JSON.parse(STDIN.read).map { |v| v["number"] }.join(" ")' 2>/dev/null)
if [ -n "$PUBLISHED" ]; then
  pass "already on RubyGems: $(echo "$PUBLISHED" | tr ' ' '\n' | head -3 | tr '\n' ' ')"
  if echo " $PUBLISHED " | grep -q " $VERSION "; then
    die "$VERSION is already published. Bump with --version first."
  fi
else
  warn "could not reach RubyGems to check existing versions"
fi

# A dirty tree means the gem would not match what is committed.
if [ -n "$(git status --porcelain)" ]; then
  warn "working tree has uncommitted changes:"
  git status --short | sed 's/^/      /'
  [ "$PUBLISH" -eq 1 ] && die "commit them before publishing, so the tag matches the gem"
fi

# ---------------------------------------------------------------- build
step "Building the gem"
rm -f "$GEM_NAME-$VERSION.gem"
gem build "$GEM_NAME.gemspec" >/dev/null 2>&1 || die "gem build failed"
[ -f "$GEM_NAME-$VERSION.gem" ] || die "expected $GEM_NAME-$VERSION.gem, but it was not produced"
mkdir -p pkg && mv "$GEM_NAME-$VERSION.gem" "pkg/"
GEM_PATH="pkg/$GEM_NAME-$VERSION.gem"
pass "$GEM_PATH ($(du -h "$GEM_PATH" | cut -f1))"

# What actually ships. The gemspec globs lib/ only, so a stray file is worth seeing.
step "Gem contents"
gem contents --spec-file "$GEM_NAME.gemspec" 2>/dev/null | sed "s|$ROOT/||" | sed 's/^/  /' \
  || tar -xOf "$GEM_PATH" data.tar.gz 2>/dev/null | tar -tzf - 2>/dev/null | sed 's/^/  /'

if [ "$PUBLISH" -eq 0 ]; then
  printf '\n\033[32mBuilt %s.\033[0m Nothing was published.\n' "$GEM_PATH"
  printf 'Install locally to test:  gem install %s\n' "$GEM_PATH"
  printf 'Publish with:             scripts/release-gem.sh --publish\n\n'
  exit 0
fi

# ---------------------------------------------------------------- publish
step "Publishing to RubyGems"
printf '  About to push \033[1m%s %s\033[0m to RubyGems. This cannot be undone.\n' "$GEM_NAME" "$VERSION"
printf '  Continue? (y/N): '
read -r answer < /dev/tty
case "$answer" in
  y|Y) ;;
  *) die "Cancelled." ;;
esac

gem push "$GEM_PATH" || die "gem push failed — check your RubyGems credentials (gem signin)"
pass "published $GEM_NAME $VERSION"

step "Tagging"
TAG="v$VERSION"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  warn "tag $TAG already exists"
else
  git tag -a "$TAG" -m "$GEM_NAME $VERSION"
  pass "created tag $TAG"
fi

printf '\n\033[32mDone.\033[0m Push the tag when ready:\n'
printf '  git push origin %s\n\n' "$TAG"
