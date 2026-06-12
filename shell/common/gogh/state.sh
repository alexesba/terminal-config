#!/usr/bin/env bash
# Per-terminal Gogh theme state stored as JSON in ~/.local/state/gogh/current.
#
#   { "alacritty": { "name": "...", "file": "theme.sh" }, "kitty": { ... }, "wezterm": { ... }, "last_active": "kitty" }
#
# Sourced by persist.sh, current.sh, apply_saved.sh, apply_persisted.sh.
set -u

GOGH_STATE_TERMINALS=(alacritty kitty wezterm)

gogh_state_path() {
  printf '%s\n' "${GOGH_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/gogh/current}"
}

# Run the embedded Python state helper (see gogh_state_py below).
_gogh_state_py() {
  GOGH_STATE_PATH="$(gogh_state_path)" python3 - "$@" <<'PY'
import json
import os
import re
import sys

STATE_PATH = os.environ["GOGH_STATE_PATH"]
TERMINALS = ("alacritty", "kitty", "wezterm")
EMPTY = {t: {} for t in TERMINALS}


def empty_state():
    data = dict(EMPTY)
    data["last_active"] = ""
    return data


def parse_legacy(text):
    fields = {}
    for line in text.splitlines():
        m = re.match(r"^(name|file|terminal)=(.*)$", line.strip())
        if m:
            fields[m.group(1)] = m.group(2)
    return fields


def seed_from_configs(data):
    home = os.environ.get("HOME", "")
    if not home:
        return data

    wez_cfg = os.environ.get("WEZTERM_CONFIG_DIR") or os.path.join(home, ".config", "wezterm")
    colors_lua = os.path.join(wez_cfg, "colors.lua")
    if not (data.get("wezterm") or {}).get("file") and os.path.isfile(colors_lua):
        with open(colors_lua, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("-- Source theme: "):
                    data.setdefault("wezterm", {})["file"] = line.split(": ", 1)[1].strip()
                    break

    kitty_cfg = os.environ.get("KITTY_CONFIG_DIRECTORY") or os.path.join(home, ".config", "kitty")
    colors_conf = os.path.join(kitty_cfg, "colors.conf")
    if not (data.get("kitty") or {}).get("name") and os.path.isfile(colors_conf):
        with open(colors_conf, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("# Color theme: "):
                    data.setdefault("kitty", {})["name"] = line.split(": ", 1)[1].strip()
                    break

    return data


def migrate_legacy(text):
    fields = parse_legacy(text)
    data = empty_state()
    term = fields.get("terminal", "").strip()
    name = fields.get("name", "").strip()
    file_ = fields.get("file", "").strip()
    if term in TERMINALS and (name or file_):
        entry = {}
        if name:
            entry["name"] = name
        if file_:
            entry["file"] = file_
        data[term] = entry
        data["last_active"] = term
    elif name or file_:
        # Legacy global state with no terminal=: treat as WezTerm (previous default target).
        entry = {}
        if name:
            entry["name"] = name
        if file_:
            entry["file"] = file_
        data["wezterm"] = entry
        data["last_active"] = "wezterm"
    return seed_from_configs(data)


def load_state():
    if not os.path.isfile(STATE_PATH):
        return empty_state()
    with open(STATE_PATH, encoding="utf-8") as fh:
        text = fh.read()
    stripped = text.strip()
    if not stripped:
        return empty_state()
    if stripped.startswith("{"):
        data = json.loads(text)
        for term in TERMINALS:
            data.setdefault(term, {})
        data.setdefault("last_active", "")
        return data
    return migrate_legacy(text)


def save_state(data):
    os.makedirs(os.path.dirname(STATE_PATH) or ".", exist_ok=True)
    out = {t: data.get(t) or {} for t in TERMINALS}
    out["last_active"] = data.get("last_active") or ""
    with open(STATE_PATH, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2, sort_keys=True)
        fh.write("\n")


def main():
    cmd = sys.argv[1]
    if cmd == "get":
        term, field = sys.argv[2], sys.argv[3]
        data = load_state()
        if term == "last_active":
            print(data.get("last_active") or "")
            return
        entry = data.get(term) or {}
        print(entry.get(field) or "")
    elif cmd == "theme":
        term = sys.argv[2]
        data = load_state()
        entry = data.get(term) or {}
        name = entry.get("name") or ""
        file_ = entry.get("file") or ""
        sys.stdout.write(f"{name}\t{file_}")
    elif cmd == "set":
        term, name, file_ = sys.argv[2], sys.argv[3], sys.argv[4]
        if term not in TERMINALS:
            sys.exit(1)
        data = load_state()
        entry = {}
        if name:
            entry["name"] = name
        if file_:
            entry["file"] = file_
        data[term] = entry
        data["last_active"] = term
        save_state(data)
    elif cmd == "set_last_active":
        term = sys.argv[2]
        if term not in TERMINALS:
            sys.exit(1)
        data = load_state()
        data["last_active"] = term
        save_state(data)
    elif cmd == "migrate":
        if not os.path.isfile(STATE_PATH):
            return
        with open(STATE_PATH, encoding="utf-8") as fh:
            text = fh.read()
        if text.strip().startswith("{"):
            return
        data = migrate_legacy(text)
        save_state(data)
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()
PY
}

# Ensure legacy flat state is migrated to JSON on first use.
gogh_state_migrate_legacy() {
  _gogh_state_py migrate 2>/dev/null || true
}

# Print name<TAB>file for terminal $1 (may be empty).
gogh_state_theme_for_terminal() {
  local term="${1:-}"
  [ -n "$term" ] || return 1
  gogh_state_migrate_legacy
  _gogh_state_py theme "$term" 2>/dev/null || true
}

# Print last_active terminal id (alacritty|kitty|wezterm) or empty.
gogh_state_last_active() {
  gogh_state_migrate_legacy
  _gogh_state_py get last_active name 2>/dev/null || true
}

# Persist theme for terminal $1.
gogh_state_write_theme() {
  local term="${1:-}" name="${2:-}" file="${3:-}"
  [ -n "$term" ] || return 1
  gogh_state_migrate_legacy
  _gogh_state_py set "$term" "$name" "$file"
}

# Record which emulator was synced (no theme change).
gogh_state_write_last_active() {
  local term="${1:-}"
  [ -n "$term" ] || return 0
  gogh_state_migrate_legacy
  _gogh_state_py set_last_active "$term" 2>/dev/null || true
}
