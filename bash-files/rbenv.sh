# rbenv
if [ -d "$HOME/.rbenv/bin" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
fi

if which rbenv > /dev/null; then
  eval "$(rbenv init -)";
fi

# On macOS, point ruby-build to Homebrew's libffi so Ruby compiles correctly
if [[ "$OSTYPE" =~ ^darwin ]] && command -v brew &>/dev/null; then
  local _libffi
  _libffi="$(brew --prefix libffi 2>/dev/null)"
  if [[ -d "$_libffi" ]]; then
    export LDFLAGS="-L${_libffi}/lib ${LDFLAGS}"
    export CPPFLAGS="-I${_libffi}/include ${CPPFLAGS}"
    export PKG_CONFIG_PATH="${_libffi}/lib/pkgconfig:${PKG_CONFIG_PATH}"
  fi
  unset _libffi
fi
