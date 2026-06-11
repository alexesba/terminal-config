_colorscheme_help() {
  cat <<EOF
Usage: colorscheme [-h|--help] [update|--update]

  colorscheme            Fuzzy-pick and apply a Gogh theme
  colorscheme update     Pull latest themes from GitHub (GOGH_DIR, default ~/src/gogh)

Alias: color_scheme (-h and --help show this message)
EOF
}

function colorscheme() {
  local gogh_root="${GOGH_DIR:-$HOME/src/gogh}"
  local update_script="$DOTFILES_DIR/shell/common/gogh/update.sh"

  case "${1:-}" in
    -h|--help|help)
      _colorscheme_help
      return 0
      ;;
    update|--update)
      case "${2:-}" in
        -h|--help|help)
          _colorscheme_help
          return 0
          ;;
      esac
      bash "$update_script" "$gogh_root"
      return $?
      ;;
  esac

  # GOGH_DIR points at the Gogh repo root (matches bootstrap.sh); themes live in
  # its installs/ subdirectory.
  local gogh_dir="$gogh_root/installs"
  if [ ! -d "$gogh_dir" ]; then
    echo "gogh themes not found at $gogh_dir"
    echo "Clone it: git clone https://github.com/Gogh-Co/Gogh ~/src/gogh"
    echo "Or set GOGH_DIR in ~/.local.sh to point to your Gogh checkout."
    return 1
  fi
  local preview_script="$DOTFILES_DIR/shell/common/gogh/preview.sh"
  local persist_script="$DOTFILES_DIR/shell/common/gogh/persist.sh"
  local current_script="$DOTFILES_DIR/shell/common/gogh/current.sh"
  local list_script="$DOTFILES_DIR/shell/common/gogh/list.sh"

  local current_line current_name current_file fzf_header theme_path
  current_line=$(bash "$current_script" "$gogh_dir" 2>/dev/null || true)
  current_name="${current_line%%$'\t'*}"
  current_file="${current_line#*$'\t'}"
  theme_path="$gogh_dir/$current_file"
  fzf_header=$(bash "$list_script" header "$theme_path" "$current_name")

  # Build a "Human Name<TAB>file.sh" list (one awk pass): show each theme's
  # PROFILE_NAME, falling back to a prettified filename. fzf displays only the
  # name (--with-nth=1) but returns the real filename (--accept-nth=2).
  # The active theme is marked with ●; its name is colorized in the header.
  local selection
  selection=$(awk -F'"' '
    function flush() {
      if (curfile != "") {
        if (pname != "") disp = pname
        else { disp = base; sub(/\.sh$/, "", disp); gsub(/-/, " ", disp) }
        printf "%s\t%s\n", disp, base
      }
    }
    FNR == 1 { flush(); curfile = FILENAME; pname = ""; n = split(FILENAME, a, "/"); base = a[n] }
    /^export PROFILE_NAME=/ { pname = $2 }
    END { flush() }
  ' "$gogh_dir"/*.sh | sort -f | bash "$list_script" "$gogh_dir" "$current_file" "$current_name" | fzf \
    --ansi \
    --height=100% \
    --delimiter='\t' --with-nth=1 --accept-nth=2 \
    --header "$fzf_header" \
    --prompt='colorscheme> ' \
    --preview "bash '$preview_script' '$gogh_dir'/{2}" \
    --preview-window='up:50%:border-bottom:wrap') || return

  [ -z "$selection" ] && return
  sh "$gogh_dir/$selection"
  # Persist the choice so it survives new terminal windows (e.g. WezTerm, which
  # gogh otherwise only themes for the current session).
  [ -f "$persist_script" ] && bash "$persist_script" "$gogh_dir/$selection" "${TERMINAL:-}"
}

color_scheme() { colorscheme "$@"; }
