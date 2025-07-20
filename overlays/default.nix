{ inputs, outputs }:
{
  default = final: prev: {
    nix-pkgconfig = final.callPackage ../pkgs/nix-pkgconfig { };
    
    # Wrapper version that replaces pkg-config system-wide
    nix-pkgconfig-wrapped = final.writeShellScriptBin "pkg-config" ''
      exec ${final.nix-pkgconfig}/bin/pkg-config "$@"
    '';
  };
}
