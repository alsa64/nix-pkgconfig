# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`nix-pkgconfig` is a modern Nix-based wrapper for `pkg-config` that allows nix-unaware applications (e.g. `cabal-install`) to use packages from `nixpkgs` to satisfy native library dependencies. The project follows modern Nix flake patterns with proper modules, overlays, and multi-platform support.

## Architecture

- **Core wrapper**: `pkgs/nix-pkgconfig/pkg-config` - Python script that intercepts pkg-config calls and uses Nix to provide dependencies
- **Database builder**: `pkgs/nix-pkgconfig/build-pc-index.py` - Generates mappings between .pc files and nixpkgs attributes using nix-locate
- **Package definition**: `pkgs/nix-pkgconfig/default.nix` - Modern Nix derivation with proper metadata and wrapping
- **NixOS module**: `modules/nixos.nix` - System-level configuration module
- **Home Manager module**: `modules/home-manager.nix` - User-level configuration module
- **Overlay**: `overlays/default.nix` - Provides `nix-pkgconfig` and `nix-pkgconfig-wrapped` packages
- **Modern flake**: Uses flake-utils, proper outputs structure, and development shell

## Common Commands

### Development

```sh
# Enter development shell with all dependencies
nix develop

# Format Nix code
nix fmt

# Build all packages
nix build .#nix-pkgconfig
nix build .#nix-pkgconfig-wrapped
```

### Building the database

```sh
# Using the built package
nix run .#nix-pkgconfig -- nix-pkgconfig-build-database

# Or if installed system-wide
nix-pkgconfig-build-database
```

### Testing module integration

```sh
# Test NixOS module
nix build .#nixosConfigurations.test.config.system.build.toplevel

# Test Home Manager module
nix build .#homeConfigurations.test.activationPackage
```

## Module Configuration

The project provides both NixOS and Home Manager modules with these options:

- `programs.nix-pkgconfig.enable` - Enable the service
- `programs.nix-pkgconfig.package` - Which package to use
- `programs.nix-pkgconfig.wrapPkgConfig` - Whether to wrap system pkg-config

When `wrapPkgConfig = true`, both `pkg-config` and `pkgconfig` commands are wrapped.

### Module Import Patterns

Modules can be imported in two ways:

1. **Direct imports**: Use `nixosModules.default` or `homeManagerModules.default`
2. **System-level imports**: Use `nixosModules.nix-pkgconfig` or `homeManagerModules.nix-pkgconfig` in system module lists

The second pattern is useful for flake-based system configurations where you want to include the module directly in the system's module list rather than importing it in individual configuration files.

## Key Implementation Details

- Uses `makeWrapper` for proper runtime dependency injection
- Includes proper `meta` attributes following nixpkgs conventions
- Database files stored in `$out/share/nix-pkgconfig/` for module consumption
- Supports both standalone and wrapped installation modes
- Runtime dependencies (nix, nix-index) are properly wrapped into PATH
- Environment variables `NIX_PKGCONFIG_DATABASES` and `NIX_PKGCONFIG_NIXPKGS_PATH` for customization

## File Structure

- `pkgs/nix-pkgconfig/` - Main package source and scripts
- `modules/` - NixOS and Home Manager modules
- `overlays/` - Package overlays
- `flake.nix` - Modern flake with proper outputs structure
- `flake.lock` - Flake input locks
