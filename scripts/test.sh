#!/usr/bin/env bash
# Run static checks and bats tests locally (same as CI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "━━━  Syntax check  ━━━"
while IFS= read -r script; do
  bash -n "$script"
done < <(find . -name '*.sh' -not -path './.git/*' -not -path './shell/zsh/*' | sort)
while IFS= read -r script; do
  zsh -n "$script"
done < <(find ./shell/zsh -name '*.sh' 2>/dev/null | sort)
echo "  ✓  All shell scripts parse cleanly."
echo ""

if command -v shellcheck &>/dev/null; then
  echo "━━━  shellcheck  ━━━"
  # Entry-point and lib scripts only — shell/*.sh are sourced fragments (no shebang).
  for script in install.sh update.sh uninstall.sh bootstrap.sh lib/*.sh scripts/*.sh; do
    shellcheck -S warning "$script"
  done
  echo "  ✓  shellcheck passed."
  echo ""
else
  echo "━━━  shellcheck  ━━━"
  echo "  ⚠  shellcheck not installed — skipping (brew install shellcheck)"
  echo ""
fi

if command -v bats &>/dev/null; then
  echo "━━━  bats  ━━━"
  bats tests/
else
  echo "━━━  bats  ━━━"
  echo "  ⚠  bats not installed — skipping (brew install bats-core)"
  exit 1
fi
