{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.nix-pkg-config;
in
{
  options.programs.nix-pkg-config = {
    enable = lib.mkEnableOption "nix-pkg-config, a wrapper for pkg-config that uses nixpkgs";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nix-pkg-config;
      defaultText = lib.literalExpression "pkgs.nix-pkg-config";
      description = "The nix-pkg-config package to use.";
    };

    wrapPkgConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to wrap the system pkg-config command with nix-pkg-config.
        When enabled, pkg-config commands will automatically use nixpkgs packages.
        When disabled, only the nix-pkg-config binary will be available.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      if cfg.wrapPkgConfig then
        [
          (pkgs.writeShellScriptBin "pkg-config" ''
            exec ${cfg.package}/bin/nix-pkg-config "$@"
          '')
          (pkgs.writeShellScriptBin "pkgconfig" ''
            exec ${cfg.package}/bin/nix-pkg-config "$@"
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
