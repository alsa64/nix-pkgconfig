# nix-pkgconfig

`nix-pkgconfig` is a wrapper for `pkg-config` allowing nix-unaware applications (e.g.
`cabal-install`) to use packages from `nixpkgs` (to satisfy native library
dependencies).

## Installation

### Using NixOS Module

#### Option 1: Import from flake inputs
Add to your `configuration.nix`:

```nix
{
  inputs.nix-pkgconfig.url = "github:vyls/nix-pkgconfig";

  # In your configuration
  imports = [ inputs.nix-pkgconfig.nixosModules.default ];

  programs.nix-pkgconfig = {
    enable = true;
    wrapPkgConfig = true; # Replace system pkg-config with nix-pkgconfig
  };
}
```

#### Option 2: Direct module import
Add to your system modules:

```nix
{
  inputs.nix-pkgconfig.url = "github:vyls/nix-pkgconfig";

  # In your system configuration
  nixosConfigurations.your-system = nixpkgs.lib.nixosSystem {
    modules = [
      ./configuration.nix
      inputs.nix-pkgconfig.nixosModules.nix-pkgconfig
      {
        programs.nix-pkgconfig.enable = true;
        programs.nix-pkgconfig.wrapPkgConfig = true;
      }
    ];
  };
}
```

### Using Home Manager Module

#### Option 1: Import from flake inputs
Add to your `home.nix`:

```nix
{
  inputs.nix-pkgconfig.url = "github:vyls/nix-pkgconfig";

  # In your home configuration
  imports = [ inputs.nix-pkgconfig.homeManagerModules.default ];

  programs.nix-pkgconfig = {
    enable = true;
    wrapPkgConfig = false; # Just provide nix-pkgconfig binary
  };
}
```

#### Option 2: Direct module import
Add to your home configuration modules:

```nix
{
  inputs.nix-pkgconfig.url = "github:vyls/nix-pkgconfig";

  # In your home configuration
  homeConfigurations.your-user = home-manager.lib.homeManagerConfiguration {
    modules = [
      ./home.nix
      inputs.nix-pkgconfig.homeManagerModules.nix-pkgconfig
      {
        programs.nix-pkgconfig.enable = true;
        programs.nix-pkgconfig.wrapPkgConfig = false;
      }
    ];
  };
}
```

### Manual Installation

Install directly from the flake:

```sh
# Install as nix-pkgconfig binary only
nix profile install github:vyls/nix-pkgconfig

# Or use in a shell
nix shell github:vyls/nix-pkgconfig

# Build locally
nix build .#nix-pkgconfig
```

### Using Overlay

In your flake:

```nix
{
  inputs.nix-pkgconfig.url = "github:vyls/nix-pkgconfig";

  nixpkgs.overlays = [ inputs.nix-pkgconfig.overlays.default ];

  # Now available as: pkgs.nix-pkgconfig and pkgs.nix-pkgconfig-wrapped
}
```

## Configuration Options

The modules support the following options:

- `enable`: Enable nix-pkgconfig
- `package`: Which package to use (default: `pkgs.nix-pkgconfig`)
- `wrapPkgConfig`: Whether to wrap system `pkg-config` commands (default: `false`)

When `wrapPkgConfig = true`, both `pkg-config` and `pkgconfig` commands will use nix-pkgconfig automatically.

## Database Setup

`nix-pkgconfig` relies on a database of mappings between `pkg-config` `.pc`
files and the `nixpkgs` attributes they are provided by.

### Automatic Setup

When using the modules, a minimal database is automatically installed. For home-manager, the database directory is created and the default database is copied on first activation.

### Manual Database Setup

```sh
# Install minimal database
mkdir -p $XDG_CONFIG_HOME/nix-pkgconfig
cp $(nix build --no-link --print-out-paths .#nix-pkgconfig)/share/nix-pkgconfig/default-database.json \
   $XDG_CONFIG_HOME/nix-pkgconfig/001-default.json
```

### Building Complete Database

For better coverage, build a complete database covering most of nixpkgs:

```sh
# Using the installed script
nix-pkgconfig-build-database

# Or directly from the repo
nix run .#nix-pkgconfig -- nix-pkgconfig-build-database
```

This creates a comprehensive database at `$XDG_CONFIG_HOME/nix-pkgconfig/002-nixpkgs.json`.

## Usage

Once configured, `pkg-config` calls will automatically use nixpkgs packages:

```sh
$ pkg-config --cflags libpq
-I/nix/store/...-postgresql-15.4/include

$ pkg-config --libs zlib
-L/nix/store/...-zlib-1.2.13/lib -lz
```

### Usage with cabal-install

For Haskell projects, either:

1. Use the wrapper mode (`wrapPkgConfig = true`) for automatic integration
2. Explicitly specify the pkg-config binary:

```sh
cabal build --with-pkg-config=$(which nix-pkgconfig)
```

3. Copy the included `cabal.project.local` to enable pkg-config flags:

```cabal
package postgresql-libpq
  flags: use-pkg-config

package zlib
  flags: pkg-config
```

## Development

```sh
# Enter development shell
nix develop

# Format code
nix fmt

# Build and test
nix build
nix run .#nix-pkgconfig -- --help
```
