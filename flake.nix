{
  description = "My Nix based Configurations";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: import ./pkgs inputs.nixpkgs.legacyPackages.${system});
      formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      overlays = import ./overlays { inherit inputs outputs; };
    };
}
