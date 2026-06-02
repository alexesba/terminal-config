# ── zsh-autosuggestions ───────────────────────────────────────────────────────
# Tries Homebrew (Apple Silicon, then Intel), then a manual clone fallback.
_autosugg_paths=(
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
)

for _path in "${_autosugg_paths[@]}"; do
  if [ -f "$_path" ]; then
    source "$_path"
    break
  fi
done
unset _path _autosugg_paths

# Strategy: match against history first, then fall back to completions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Dim gray — readable but clearly distinct from what you're typing
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6b6b6b"

# Accept the full suggestion with → or Ctrl+Space
bindkey '^ ' autosuggest-accept   # Ctrl+Space
