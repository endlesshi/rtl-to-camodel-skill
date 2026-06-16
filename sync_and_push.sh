#!/usr/bin/env bash
set -euo pipefail

SRC="${RTL_TO_CAMODEL_SKILL_SRC:-$HOME/.codex/skills/rtl-to-camodel}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DST="$REPO_DIR/rtl-to-camodel"
COMMIT_MSG="${1:-sync rtl-to-camodel skill from codex}"

if [[ ! -d "$SRC" ]]; then
  echo "Source skill directory not found: $SRC" >&2
  exit 1
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "This script must live in the rtl-to-camodel-skill git repository." >&2
  exit 1
fi

mkdir -p "$DST"
rsync -a --delete \
  --exclude ".git" \
  --exclude ".DS_Store" \
  "$SRC"/ "$DST"/

cd "$REPO_DIR"

if git diff --quiet -- rtl-to-camodel sync_and_push.sh; then
  echo "No rtl-to-camodel skill changes to commit."
else
  git status --short
  git add rtl-to-camodel sync_and_push.sh
  git commit -m "$COMMIT_MSG"
fi

git push
