{
  description = "A wrapper for pkg-config that uses nixpkgs packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:
    let
      inherit (self) outputs;
      systems = flake-utils.lib.defaultSystems;
      forEachSystem = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      treefmtEval = forEachSystem (
        system:
        treefmt-nix.lib.evalModule (pkgsFor system) {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            shfmt.enable = true;
            shellcheck.enable = true;
            prettier.enable = true;
            taplo.enable = true;
            ruff-format.enable = true;
            ruff-check.enable = true;
          };
          settings.global.excludes = [
            "*.gif"
            "*.jpg"
            "*.jpeg"
            "*.png"
            "*.webp"
            "*.svg"
            "*.lock"
            "*.log"
            "result*"
            ".direnv/"
            "_build/"
            "dist/"
            "node_modules/"
          ];
        }
      );
    in
    {
      # Packages for each system
      packages = forEachSystem (system: {
        default = self.packages.${system}.nix-pkgconfig;
        nix-pkgconfig = (pkgsFor system).nix-pkgconfig;
        nix-pkgconfig-wrapped = (pkgsFor system).nix-pkgconfig-wrapped;
      });

      # Overlays
      overlays = import ./overlays {
        inputs = { };
        inherit outputs;
      };

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
            # Formatting tools
            treefmtEval.${system}.config.build.wrapper
            nixfmt-rfc-style
            shfmt
            shellcheck
            ruff
            prettier
            taplo
            codespell
          ];
        };
      });

      # Formatter
      formatter = forEachSystem (system: treefmtEval.${system}.config.build.wrapper);

      # Checks
      checks = forEachSystem (system: {
        nix-pkgconfig = self.packages.${system}.nix-pkgconfig;
        formatting = treefmtEval.${system}.config.build.check self;
      });
    };
}
