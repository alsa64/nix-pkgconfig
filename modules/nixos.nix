{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.nix-pkgconfig;
in
{
  options.programs.nix-pkgconfig = {
    enable = lib.mkEnableOption "nix-pkgconfig, a wrapper for pkg-config that uses nixpkgs";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nix-pkgconfig;
      defaultText = lib.literalExpression "pkgs.nix-pkgconfig";
      description = "The nix-pkgconfig package to use.";
    };

    wrapPkgConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to wrap the system pkg-config command with nix-pkgconfig.
        When enabled, pkg-config commands will automatically use nixpkgs packages.
        When disabled, only the nix-pkgconfig binary will be available.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      if cfg.wrapPkgConfig then
        [
          (pkgs.writeShellScriptBin "pkg-config" ''
            exec ${cfg.package}/bin/pkg-config "$@"
          '')
          (pkgs.writeShellScriptBin "pkgconfig" ''
            exec ${cfg.package}/bin/pkg-config "$@"
          '')
        ]
      else
        [
          cfg.package
        ];

    # Ensure nix-index is available for database building
    programs.nix-index.enable = lib.mkDefault true;
  };
}
