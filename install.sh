#!/usr/bin/env bash
# Install one skill from this repo into the local OpenClaw skills directory.
# Usage: install.sh [skill-name]   (default: octo-multica-cloud)
# Honors OPENCLAW_SKILLS_DIR; defaults to ~/.openclaw/skills.
set -euo pipefail

SKILL="${1:-octo-multica-cloud}"
DEST="${OPENCLAW_SKILLS_DIR:-$HOME/.openclaw/skills}"
REPO="https://github.com/Mininglamp-OSS/octo-skills.git"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 "$REPO" "$TMP/repo" >/dev/null 2>&1

if [ ! -d "$TMP/repo/$SKILL" ]; then
  echo "error: skill '$SKILL' not found in repo. Available:" >&2
  find "$TMP/repo" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -printf '  - %f\n' >&2
  exit 1
fi

mkdir -p "$DEST"
cp -r "$TMP/repo/$SKILL" "$DEST/"
echo "installed -> $DEST/$SKILL"
echo "next: tell your agent to run the skill's first-run onboarding to configure the key."
