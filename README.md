# nix-pkgconfig

`nix-pkgconfig` is a wrapper for `pkg-config` allowing nix-unaware applications (e.g.
`cabal-install`) to use packages from `nixpkgs` (to satisfy native library
dependencies).

## Getting started

`nix-pkgconfig` relies on a database of mappings between `pkg-config` `.pc`
files and the `nixpkgs` attribute they are provided by. A minimal example
database (`default-database.json`) is included which can be installed via:

```sh
mkdir -p $XDG_CONFIG_HOME/nix-pkgconfig
cp default-database.json $XDG_CONFIG_HOME/nix-pkgconfig/001-default.json
```

However, it is recommended that you build a more complete database covering
nearly all of `nixpkgs`. This can be built using the `build-database.sh` script:

```sh
./build-database.sh
```

The script is provided by the `nix-pkgconfig` package, build it by running:

```sh
nix build .#nix-pkgconfig
```

The repository also contains an overlay, making it easy to deploy nix-pkgconfig
in any flake based environment.

When called the `pkg-config` wrapper will consult the database looking for the
`nix` derivation providing each requested package, build it, and run the
requested `pkg-config` invocation. For instance, we can run:

```sh
$ pkg-config --cflags libpq
-I/nix/store/53kwps1ndh29wgjjwa7qf06ygvjxfs09-postgresql-9.6.11/include
```

## Usage with cabal-install

To use this with `cabal-install` you may either place `pkg-config` in `PATH` as
described above or explicitly point `cabal` at the `pkg-config` script:

```sh
cabal new-build --with-pkg-config=$PATH_TO_THIS_REPO/pkg-config
```

Alternatively, you might consider either adding `nix-pkgconfig` to
`environment.systemPackages` or your account's mutable environment (e.g.
`nix profile install .#nix-pkgconfig`).

Note that some packages respect the `pkg-config` flag to enable
`pkg-config`-based native library discovery. The included
`cabal.project.local` includes some `project` stanzas to enable the necessary
flags with cabal `new-build`. Copy these into your project's
`cabal.project.local` if you intend on using `nix-pkgconfig`.
