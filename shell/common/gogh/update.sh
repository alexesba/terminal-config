#!/usr/bin/env bash
# Update the local Gogh checkout (bootstrap.sh clones with --depth 1).
#
# Usage: update.sh [gogh_repo_root]

repo="${1:-${GOGH_DIR:-$HOME/src/gogh}}"

if [ ! -d "$repo/.git" ]; then
  echo "Gogh not found at $repo (not a git repository)." >&2
  echo "Install with: ./bootstrap.sh --gogh" >&2
  echo "Or: git clone --depth 1 https://github.com/Gogh-Co/Gogh \"$repo\"" >&2
  exit 1
fi

if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
  echo "Gogh has local changes; commit or stash before updating." >&2
  exit 1
fi

branch="$(git -C "$repo" symbolic-ref -q --short HEAD 2>/dev/null || true)"
if [ -z "$branch" ]; then
  branch="$(git -C "$repo" remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')"
fi
branch="${branch:-master}"

echo "Updating Gogh at $repo…"

if git -C "$repo" pull --ff-only --depth=1 2>/dev/null; then
  :
elif git -C "$repo" pull --ff-only 2>/dev/null; then
  :
# Shallow clones can diverge when upstream history is rewritten (common with
# Gogh's automated commits). Fetch latest and reset to match origin.
elif git -C "$repo" fetch origin "$branch" --depth=1 2>/dev/null \
  && git -C "$repo" reset --hard "origin/$branch" 2>/dev/null; then
  :
else
  echo "Update failed. From $repo try:" >&2
  echo "  git fetch origin $branch --depth=1 && git reset --hard origin/$branch" >&2
  echo "Or re-clone: rm -rf \"$repo\" && ./bootstrap.sh --gogh" >&2
  exit 1
fi

if [ -d "$repo/installs" ]; then
  count="$(find "$repo/installs" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')"
  echo "✓  Gogh updated ($count themes in installs/)."
else
  echo "✓  Gogh updated."
fi
