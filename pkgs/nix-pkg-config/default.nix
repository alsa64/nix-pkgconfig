{
  lib,
  stdenv,
  python3,
  nix,
  nix-index,
  makeWrapper,
}:

# Ensure we're using a modern Python version (3.11+)
assert lib.versionAtLeast python3.version "3.11";

stdenv.mkDerivation (finalAttrs: {
  pname = "nix-pkg-config";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ python3 ];

  # Ensure Python version compatibility
  pythonPath = [ python3.pkgs.setuptools ];

  dontBuild = true;

  installPhase = ''
        runHook preInstall

        mkdir -p $out/bin $out/share/nix-pkg-config

        # Install the main Python script (unwrapped for development use)
        cp src/pkg_config.py $out/bin/pkg-config.py
        chmod +x $out/bin/pkg-config.py
        
        # Create a wrapper script without .py extension  
        cat > $out/bin/pkg-config <<EOF
    #!/bin/sh
    exec "${python3.interpreter}" "$out/bin/nix-pkg-config.py" "\$@"
    EOF
        chmod +x $out/bin/pkg-config
        
        # Create wrapped version of Python script for Nix runtime
        cp src/pkg_config.py $out/bin/nix-pkg-config.py
        chmod +x $out/bin/nix-pkg-config.py

        # Install helper scripts
        cp src/build-database.sh $out/bin/nix-pkg-config-build-database
        cp src/build_pc_index.py $out/bin/nix-pkg-config-build-pc-index
        chmod +x $out/bin/nix-pkg-config-build-database
        chmod +x $out/bin/nix-pkg-config-build-pc-index

        # Install default database
        cp src/default-database.json $out/share/nix-pkg-config/default-database.json

        # Wrap the runtime version with proper dependencies  
        wrapProgram $out/bin/nix-pkg-config.py \
          --prefix PATH : ${lib.makeBinPath [ nix ]} \
          --prefix PYTHONPATH : ${python3.pkgs.makePythonPath finalAttrs.pythonPath} \
          --set NIX_PATH nixpkgs=${"\${NIX_PATH:-<nixpkgs>}"}
        
        # The shell wrapper just needs to find the wrapped Python script
        wrapProgram $out/bin/pkg-config \
          --prefix PATH : ${lib.makeBinPath [ nix ]}

        wrapProgram $out/bin/nix-pkg-config-build-database \
          --prefix PATH : ${
            lib.makeBinPath [
              nix
              nix-index
              python3
            ]
          } \
          --prefix PYTHONPATH : ${python3.pkgs.makePythonPath finalAttrs.pythonPath} \
          --set NIX_PATH nixpkgs=${"\${NIX_PATH:-<nixpkgs>}"} \
          --set PYTHON ${python3.interpreter}

        wrapProgram $out/bin/nix-pkg-config-build-pc-index \
          --prefix PATH : ${lib.makeBinPath [ nix-index ]} \
          --prefix PYTHONPATH : ${python3.pkgs.makePythonPath finalAttrs.pythonPath} \
          --set PYTHON ${python3.interpreter}

        runHook postInstall
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
    mainProgram = "pkg-config";
    # Require Python 3.11+ for modern typing features
    broken = !lib.versionAtLeast python3.version "3.11";
  };
})
