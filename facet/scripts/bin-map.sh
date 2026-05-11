#!/usr/bin/env bash
# bin-map.sh — sourced by install-deps.sh
# Binary name → Ubuntu install command mapping.
#
# WHEN A NEW EXPERIMENT DECLARES A NEW BINARY:
# Add one line here. The traversal logic in install-deps.sh never changes.
#
# SECURITY: every entry in this file is a trust boundary.
# `install_apt` uses `sudo apt-get install -y` and `install_pip` uses `pip3 install`.
# Both run arbitrary code at install time. Before adding an entry:
#   - Confirm the package name (no typosquatting).
#   - Prefer apt (signed by the distribution) over pip / curl-pipe-bash.
#   - Pin versions where possible (clangd-12, not clangd).
#   - Open a PR; reviewer must verify the source.

# --- Install helpers ---------------------------------------------------------

install_apt() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "    [dry-run] sudo apt-get install -y $1"
    return 0
  fi
  sudo apt-get install -y "$1"
}

install_pip() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "    [dry-run] pip3 install $1"
    return 0
  fi
  pip3 install --quiet "$1"
}

# --- Mapping table -----------------------------------------------------------

declare -A BIN_MAP

# C / C++ toolchain
BIN_MAP[cc]="install_apt gcc"
BIN_MAP[gcc]="install_apt gcc"
BIN_MAP[make]="install_apt make"

# Python
BIN_MAP[python3]="install_apt python3"

# Haskell
BIN_MAP[cabal]="install_apt cabal-install"
BIN_MAP[ghc]="install_apt ghc"

# LSP servers (declared via language_servers.* in profile extensions.yaml)
BIN_MAP[clangd]="install_apt clangd-12"
BIN_MAP[haskell-language-server]="install_apt haskell-language-server"
BIN_MAP[pylsp]="install_pip python-lsp-server"

# --- Add future binaries below ----------------------------------------------
# BIN_MAP[rustc]="install_apt rustc"
# BIN_MAP[cargo]="install_apt cargo"
# BIN_MAP[go]="install_apt golang-go"
# BIN_MAP[dotnet]="install_apt dotnet-sdk-8.0"
# BIN_MAP[java]="install_apt openjdk-21-jdk"

# --- Dispatcher --------------------------------------------------------------

install_binary() {
  local bin="$1"
  local recipe="${BIN_MAP[$bin]:-}"
  if [[ -z "$recipe" ]]; then
    echo "  ⚠ No install recipe for '$bin'. It must be on PATH manually." >&2
    return 1
  fi
  echo "  → $bin ($recipe)"
  $recipe
}
