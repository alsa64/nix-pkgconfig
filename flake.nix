{
  description = "A wrapper for pkg-config that uses nixpkgs packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils, ... }:
    let
      inherit (self) outputs;
      systems = flake-utils.lib.defaultSystems;
      forEachSystem = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      # Packages for each system
      packages = forEachSystem (system: {
        default = self.packages.${system}.nix-pkgconfig;
        nix-pkgconfig = (pkgsFor system).nix-pkgconfig;
        nix-pkgconfig-wrapped = (pkgsFor system).nix-pkgconfig-wrapped;
      });

      # Overlays
      overlays = import ./overlays { inputs = {}; inherit outputs; };

      # NixOS and Home Manager modules
      nixosModules.default = import ./modules/nixos.nix;
      homeManagerModules.default = import ./modules/home-manager.nix;
      
      # Config modules for direct import
      nixosModules.nix-pkgconfig = import ./modules/nixos.nix;
      homeManagerModules.nix-pkgconfig = import ./modules/home-manager.nix;

      # Development shell
      devShells = forEachSystem (system: {
        default = (pkgsFor system).mkShell {
          buildInputs = with (pkgsFor system); [
            python3
            nix-index
            nixfmt-rfc-style
          ];
        };
      });

      # Formatter
      formatter = forEachSystem (system: (pkgsFor system).nixfmt-rfc-style);

      # Checks
      checks = forEachSystem (system: {
        nix-pkgconfig = self.packages.${system}.nix-pkgconfig;
      });
    };
}
