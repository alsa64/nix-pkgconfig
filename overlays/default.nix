{ inputs, outputs }:
{
  default = final: prev: {
    nix-pkg-config = final.callPackage ../pkgs/nix-pkg-config { };

    # Wrapper version that replaces pkg-config system-wide
    nix-pkg-config-wrapped = final.writeShellScriptBin "pkg-config" ''
      exec ${final.nix-pkg-config}/bin/nix-pkg-config "$@"
    '';
  };
}
