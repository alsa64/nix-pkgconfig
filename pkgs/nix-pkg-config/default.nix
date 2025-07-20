{
  lib,
  python3,
  nix,
  nix-index,
  makeWrapper,
}:

# Ensure we're using a modern Python version (3.11+)
assert lib.versionAtLeast python3.version "3.11";

python3.pkgs.buildPythonApplication {
  pname = "nix-pkg-config";
  version = "1.0.0";
  pyproject = true;

  src = ../../.;

  build-system = [ python3.pkgs.setuptools ];
  nativeBuildInputs = [ makeWrapper ];

  # Runtime dependencies
  propagatedBuildInputs = [
    nix
    nix-index
  ];

  postInstall = ''
    # Install default database
    mkdir -p $out/share/nix-pkg-config
    cp $src/pkgs/nix-pkg-config/src/nix_pkg_config/default-database.json $out/share/nix-pkg-config/default-database.json

    # Install bash script for build-database command
    cp $src/pkgs/nix-pkg-config/src/nix_pkg_config/build-database.sh $out/bin/nix-pkg-config-build-database
    chmod +x $out/bin/nix-pkg-config-build-database

    # Wrap the build-database script with proper environment
    wrapProgram $out/bin/nix-pkg-config-build-database \
      --prefix PATH : ${
        lib.makeBinPath [
          nix
          nix-index
          python3
        ]
      } \
      --set NIX_PATH "nixpkgs=\''${NIX_PATH:-<nixpkgs>}" \
      --set PYTHON ${python3.interpreter}
  '';

  meta = with lib; {
    description = "A wrapper for pkg-config that uses nixpkgs packages";
    longDescription = ''
      nix-pkg-config is a wrapper for pkg-config allowing nix-unaware applications
      (e.g. cabal-install) to use packages from nixpkgs to satisfy native library
      dependencies. It provides seamless integration between traditional build
      systems and the Nix package ecosystem.
    '';
    homepage = "https://github.com/vyls/nix-pkg-config";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "nix-pkg-config";
    # Require Python 3.11+ for modern typing features
    broken = !lib.versionAtLeast python3.version "3.11";
  };
}
