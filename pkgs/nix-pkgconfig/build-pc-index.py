#!/usr/bin/env python3
"""Build a database of pkg-config files and their nixpkgs attributes.

This script uses nix-locate to find all .pc files in nixpkgs and creates
a mapping database for nix-pkgconfig to use.
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from pathlib import Path
from subprocess import check_output

# Regular expression to match interesting .pc files in the nix store
INTERESTING_RE = re.compile(r"/nix/store/[-a-zA-Z0-9.]+/lib/pkgconfig/.*\.pc")

# Attributes to exclude from the database (conflicts or unwanted packages)
EXCLUDED_ATTRS = {
    "emscripten.out",  # Conflicts with zlib
}


def find_pc_files(nix_locate_db: str | None = None) -> dict[str, str]:
    """Find all .pc files in nixpkgs using nix-locate.

    Args:
        nix_locate_db: Optional path to nix-locate database

    Returns:
        Dictionary mapping package names to nixpkgs attributes
    """
    args = ["nix-locate", "-r", "--top-level", r".*\.pc$"]
    if nix_locate_db is not None:
        args.extend(["-d", nix_locate_db])

    try:
        output = check_output(args, text=True)
    except Exception as e:
        logging.error(f"Failed to run nix-locate: {e}")
        sys.exit(1)

    pc_files: dict[str, str] = {}
    for line in output.strip().split("\n"):
        if not line.strip():
            continue

        parts = line.split()
        if not parts:
            continue

        attr = parts[0]
        pc_file = Path(parts[-1])
        pc_name = pc_file.stem

        if is_interesting_pc_file(attr, pc_file):
            logging.debug(f"In {attr}: {pc_name} ({pc_file})")
            pc_files[pc_name] = attr
        else:
            logging.debug(f"Skipped {pc_name} from {attr}")

    return pc_files


def is_interesting_pc_file(attr: str, pc_file: Path) -> bool:
    """Check if a .pc file should be included in the database.

    Args:
        attr: The nixpkgs attribute providing the file
        pc_file: Path to the .pc file

    Returns:
        True if the file should be included, False otherwise
    """
    return attr not in EXCLUDED_ATTRS and INTERESTING_RE.match(str(pc_file)) is not None


def main() -> None:
    """Main entry point for the database builder."""
    parser = argparse.ArgumentParser(
        description="Build a database of pkg-config files and their nixpkgs attributes"
    )
    parser.add_argument(
        "-o",
        "--output",
        type=argparse.FileType("w"),
        default=sys.stdout,
        help="Output nix-pkgconfig database file (default: stdout)",
    )
    parser.add_argument(
        "-d", "--database", type=str, help="Input nix-locate database file"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Produce debug output"
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    pc_files = find_pc_files(nix_locate_db=args.database)
    logging.info(f"Found {len(pc_files)} pc files")

    json.dump(pc_files, args.output, indent=2, sort_keys=True)

    if args.output != sys.stdout:
        args.output.close()


if __name__ == "__main__":
    main()
