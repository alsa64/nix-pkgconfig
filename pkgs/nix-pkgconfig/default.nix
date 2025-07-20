{ lib
, stdenv
, python3
, nix
, nix-index
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "nix-pkgconfig";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ python3 ];

  dontBuild = true;
  
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin $out/share/nix-pkgconfig
    
    # Install the main script
    cp pkg-config $out/bin/pkg-config
    chmod +x $out/bin/pkg-config
    
    # Install helper scripts
    cp build-database.sh $out/bin/nix-pkgconfig-build-database
    cp build-pc-index.py $out/bin/nix-pkgconfig-build-pc-index
    chmod +x $out/bin/nix-pkgconfig-build-database
    chmod +x $out/bin/nix-pkgconfig-build-pc-index
    
    # Install default database
    cp default-database.json $out/share/nix-pkgconfig/default-database.json
    
    # Wrap scripts with proper runtime dependencies
    wrapProgram $out/bin/pkg-config \
      --prefix PATH : ${lib.makeBinPath [ nix ]} \
      --set NIX_PATH nixpkgs=${"\${NIX_PATH:-<nixpkgs>}"}
    
    wrapProgram $out/bin/nix-pkgconfig-build-database \
      --prefix PATH : ${lib.makeBinPath [ nix nix-index python3 ]} \
      --set NIX_PATH nixpkgs=${"\${NIX_PATH:-<nixpkgs>}"}
    
    wrapProgram $out/bin/nix-pkgconfig-build-pc-index \
      --prefix PATH : ${lib.makeBinPath [ nix-index ]}
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "A wrapper for pkg-config that uses nixpkgs packages";
    longDescription = ''
      nix-pkgconfig is a wrapper for pkg-config allowing nix-unaware applications
      (e.g. cabal-install) to use packages from nixpkgs to satisfy native library
      dependencies.
    '';
    homepage = "https://github.com/vyls/nix-pkgconfig";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
    mainProgram = "pkg-config";
  };
}
