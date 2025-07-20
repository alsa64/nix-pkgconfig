#!/usr/bin/env bash
# Build a comprehensive database for nix-pkg-config
#
# This script creates a database mapping pkg-config package names to nixpkgs
# attributes by using nix-locate to scan the entire nixpkgs repository.

set -euo pipefail

# Show usage information
show_help() {
  cat <<EOF
Usage: $0 [--help] [--update]

Builds a database of nix derivations and their provided .pc files for
nix-pkg-config

Options:
    --update   Force update of nix-locate database
    --help     Show this usage message

Environment variables:
    XDG_CACHE_HOME   Cache directory (default: ~/.cache)
    XDG_CONFIG_HOME  Config directory (default: ~/.config)
EOF
}

if [[ ${1:-} == "--help" ]]; then
  show_help
  exit 0
fi

# Set default XDG directories
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Ensure directories exist
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

# Check if nix-index database needs updating
if [[ ! -e "$XDG_CACHE_HOME/nix-index" ]] || [[ ${1:-} == "--update" ]]; then
  echo "nix-index database doesn't exist or update requested. Creating..."
  if ! nix run nixpkgs#nix-index -- nix-index; then
    echo "Error: Failed to build nix-index database" >&2
    exit 1
  fi
fi

echo "Building pkg-config database..."
if ! python3 ./build-pc-index.py -o database.json; then
  echo "Error: Failed to build database" >&2
  exit 1
fi

dest="$XDG_CONFIG_HOME/nix-pkg-config"
mkdir -p "$dest"
echo "Installing database to $dest..."

# Install databases with error checking
if [[ -f default-database.json ]]; then
  cp default-database.json "$dest/001-default.json"
else
  echo "Warning: default-database.json not found" >&2
fi

if [[ -f database.json ]]; then
  mv database.json "$dest/002-nixpkgs.json"
  echo "Successfully installed database to $dest"
else
  echo "Error: Generated database.json not found" >&2
  exit 1
fi
