#!/usr/bin/env python3
"""nix-pkgconfig: A wrapper for pkg-config that uses nixpkgs packages.

This script intercepts pkg-config calls and uses Nix to provide dependencies
from nixpkgs packages, allowing nix-unaware applications to use Nix packages.
"""

from __future__ import annotations

import json
import logging
import os
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path
from time import time
from typing import NewType

PackageName = NewType("PackageName", str)
NixAttr = NewType("NixAttr", str)


def find_databases() -> list[Path]:
    """Find available nix-pkgconfig database files.

    Returns:
        List of database file paths, either from NIX_PKGCONFIG_DATABASES
        environment variable or from the default config directory.
    """
    if databases := os.environ.get("NIX_PKGCONFIG_DATABASES"):
        return [Path(db) for db in databases.split(":") if db]

    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return sorted((config_home / "nix-pkgconfig").glob("*.json"))


def read_databases(databases: list[Path]) -> dict[PackageName, NixAttr]:
    """Read package mappings from database files.

    Args:
        databases: List of database file paths to read

    Returns:
        Dictionary mapping package names to nixpkgs attributes
    """
    pkgs: dict[PackageName, NixAttr] = {}
    for db_file in databases:
        if db_file.exists():
            logging.debug(f"Reading {db_file}")
            with db_file.open() as f:
                pkgs.update(json.load(f))
    return pkgs


def find_nixpkgs() -> str:
    """Find the nixpkgs path to use for package resolution.

    Returns:
        Path to nixpkgs, either from environment or default "<nixpkgs>"
    """
    return os.environ.get("NIX_PKGCONFIG_NIXPKGS_PATH", "<nixpkgs>")


def call_pkgconfig(attrs: list[NixAttr], args: list[str]) -> str:
    """Call pkg-config using a Nix expression with specified packages.

    Args:
        attrs: List of nixpkgs attributes to include as build inputs
        args: Arguments to pass to pkg-config

    Returns:
        Output from pkg-config command
    """
    nixpkgs = find_nixpkgs()
    nix_expr = textwrap.dedent(f"""
        let
          nixpkgs = import {nixpkgs} {{ }};
        in
        with nixpkgs; {{
          result = stdenv.mkDerivation {{
            name = "pkg-config-test";
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ {" ".join(attrs)} ];
            buildCommand = ''
              mkdir -p $out
              pkg-config {" ".join(args)} > $out/out
            '';
          }};
        }}
    """)

    with tempfile.NamedTemporaryFile("w", suffix=".nix") as f:
        f.write(nix_expr)
        f.flush()

        # Build the attribute and register roots for garbage collection protection
        if attrs:
            root_dir = Path.cwd() / ".nix-pkgconfig" / "roots"
            root_dir.mkdir(parents=True, exist_ok=True)
            link = root_dir / f"result-{time()}"
            build_cmd = ["nix", "build", "-f", nixpkgs, "-o", str(link)] + list(attrs)
            subprocess.check_output(build_cmd)

        # Run pkg-config under nix
        build_cmd = ["nix", "build", "-f", f.name, "--quiet", "--no-link", "result"]
        result = subprocess.run(build_cmd, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            sys.exit(result.returncode)

        # Read the result
        eval_cmd = ["nix", "eval", "-f", f.name, "--raw", "result.outPath"]
        out_path = Path(subprocess.check_output(eval_cmd, text=True).strip())
        return (out_path / "out").read_text()


def main() -> None:
    """Main entry point for nix-pkgconfig.

    Processes command line arguments, finds appropriate nixpkgs attributes
    for requested packages, and calls pkg-config via Nix.
    """
    dbs = find_databases()
    pkgs = read_databases(dbs)

    if "--list-all" in sys.argv:
        # Show real pkg-config packages plus our mapped packages
        result = call_pkgconfig([], sys.argv[1:])
        print(result, end="")
        for pkg in pkgs:
            print(f"{pkg}    placeholder from nix-pkgconfig")
    else:
        # Map package names to nixpkgs attributes
        attrs: list[NixAttr] = []
        pkg_names = [arg for arg in sys.argv[1:] if not arg.startswith("-")]

        for pkg_name in pkg_names:
            if attr := pkgs.get(PackageName(pkg_name)):
                attrs.append(attr)
                logging.debug(f"package {pkg_name} -> {attr}")
            else:
                logging.warning(f"failed to find nix attribute for {pkg_name}")

        result = call_pkgconfig(attrs, sys.argv[1:])
        print(result, end="")


if __name__ == "__main__":
    main()
