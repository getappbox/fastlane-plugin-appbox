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
#   scripts/release-gem.sh --publish --otp 123456    MFA code
#   scripts/release-gem.sh --publish --yes           skip the confirmation (CI)
#
# Nothing is pushed without --publish. The git tag is created locally; pushing
# it is left to you.
#
# Credentials: `gem signin` was retired by RubyGems — it no longer accepts a
# password. Create an API key with the `push_rubygem` scope at
# https://rubygems.org/profile/api_keys and then either
#
#   export GEM_HOST_API_KEY=rubygems_xxxxxxxx     (needs RubyGems >= 3.1)
#
# or write it once to ~/.gem/credentials:
#
#   mkdir -p ~/.gem && printf -- '---\n:rubygems_api_key: rubygems_xxxxxxxx\n' > ~/.gem/credentials
#   chmod 0600 ~/.gem/credentials
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

VERSION_FILE="lib/fastlane/plugin/appbox/version.rb"
GEM_NAME="fastlane-plugin-appbox"

NEW_VERSION=""
PUBLISH=0
SKIP_TESTS=0
OTP=""
ASSUME_YES=0
MODERN_RUBYGEMS=1

while [ $# -gt 0 ]; do
  case "$1" in
    --version) NEW_VERSION="${2:?--version needs a value like 4.0.1}"; shift ;;
    --publish) PUBLISH=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    --otp) OTP="${2:?--otp needs the 6-digit code}"; shift ;;
    --yes|-y) ASSUME_YES=1 ;;
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
  RSPEC_OUT="$(bundle exec rspec 2>&1)"
  if [ $? -ne 0 ]; then
    # The usual cause when switching ruby versions: the bundle was installed for
    # a different one, so nothing is actually wrong with the tests.
    if printf '%s' "$RSPEC_OUT" | grep -q "GemNotFound\|Could not find .* in locally installed gems"; then
      warn "the bundle is not installed for ruby $(ruby -e 'print RUBY_VERSION')"
      die "run 'bundle install' first (each ruby version needs its own bundle)"
    fi
    printf '%s\n' "$RSPEC_OUT" | tail -25
    die "rspec failed"
  fi
  pass "rspec ($(printf '%s' "$RSPEC_OUT" | grep -oE '[0-9]+ examples?, [0-9]+ failures?' | tail -1))"
  bundle exec rubocop >/dev/null 2>&1 || warn "rubocop reported offences (not blocking)"
  pass "rubocop run"
fi

step "Toolchain"

RUBY_VERSION_NOW="$(ruby -e 'print RUBY_VERSION')"
GEM_VERSION_NOW="$(gem --version)"
pass "ruby $RUBY_VERSION_NOW, rubygems $GEM_VERSION_NOW"

# RubyGems only learned GEM_HOST_API_KEY in 3.1, and Ruby 2.6 is long EOL.
MODERN_RUBYGEMS=1
if ruby -e 'exit(Gem::Version.new(Gem.rubygems_version.to_s) < Gem::Version.new("3.1.0") ? 0 : 1)'; then
  MODERN_RUBYGEMS=0
  warn "rubygems $GEM_VERSION_NOW is old: GEM_HOST_API_KEY is ignored, only ~/.gem/credentials works"
  warn "a newer ruby is likely already available — try:  rbenv shell 3.3.10  (or: rbenv versions)"
fi

credentials_key_usable() {
  ruby -e 'require "rubygems"; exit(Gem.configuration.rubygems_api_key.to_s.empty? ? 1 : 0)' 2>/dev/null
}

if [ "$PUBLISH" -eq 1 ]; then
  step "Credentials"

  if [ -n "${GEM_HOST_API_KEY:-}" ]; then
    pass "using GEM_HOST_API_KEY from the environment"
  elif [ -f "$HOME/.gem/credentials" ] && credentials_key_usable; then
    pass "using the API key in ~/.gem/credentials"
    perms="$(stat -f '%Lp' "$HOME/.gem/credentials")"
    [ "$perms" = "600" ] || warn "~/.gem/credentials is mode $perms; RubyGems expects 0600"
  else
    if [ -f "$HOME/.gem/credentials" ]; then
      printf '\n\033[31m✗ ~/.gem/credentials exists, but RubyGems cannot read a key from it.\033[0m\n\n'
      cat <<'HELP'
  The file has to parse as a YAML hash. The usual cause is a missing space after
  the colon: ":rubygems_api_key:rubygems_xxx" is a plain string to YAML, not a
  hash, which is what "doesn't contain valid YAML hash" is reporting.

  Correct form, and the space after the colon matters:
       ---
       :rubygems_api_key: rubygems_xxxxxxxx

HELP
      exit 1
    fi
    printf '\n\033[31m✗ No RubyGems API key found.\033[0m\n\n'
    if [ "$MODERN_RUBYGEMS" -eq 1 ]; then
      cat <<'HELP'
  `gem signin` no longer works — RubyGems retired password authentication.

  1. Create an API key with the "push_rubygem" scope:
       https://rubygems.org/profile/api_keys

  2. Either export it for this shell:
       export GEM_HOST_API_KEY=rubygems_xxxxxxxx

     or store it once:
       mkdir -p ~/.gem
       echo '---' > ~/.gem/credentials
       echo ':rubygems_api_key: rubygems_xxxxxxxx' >> ~/.gem/credentials
       chmod 0600 ~/.gem/credentials

HELP
    else
      cat <<'HELP'
  `gem signin` no longer works — RubyGems retired password authentication.

  This RubyGems is too old to read GEM_HOST_API_KEY, so the key must be stored
  in a file (or switch to a newer ruby first — see the toolchain warning above).

  1. Create an API key with the "push_rubygem" scope:
       https://rubygems.org/profile/api_keys

  2. Store it:
       mkdir -p ~/.gem
       echo '---' > ~/.gem/credentials
       echo ':rubygems_api_key: rubygems_xxxxxxxx' >> ~/.gem/credentials
       chmod 0600 ~/.gem/credentials

HELP
    fi
    exit 1
  fi
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
if [ "$ASSUME_YES" -eq 1 ]; then
  pass "confirmed by --yes"
elif [ -r /dev/tty ]; then
  printf '  Continue? (y/N): '
  answer=""
  read -r answer < /dev/tty || answer=""
  case "$answer" in
    y|Y) ;;
    *) die "Cancelled." ;;
  esac
else
  die "No terminal to confirm on. Re-run with --yes if this is intentional (e.g. CI)."
fi

PUSH_ARGS=("$GEM_PATH")
[ -n "$OTP" ] && PUSH_ARGS+=(--otp "$OTP")

if ! gem push "${PUSH_ARGS[@]}"; then
  printf '\n'
  warn "if that asked for a one-time password, re-run with:  --otp <code>"
  warn "if it rejected the key, check the scope includes push_rubygem"
  die "gem push failed"
fi
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
