final: prev: {
  uboot_NanopiR4S = prev.buildUBoot {
    defconfig = "nanopi-r4s-rk3399_defconfig";
    extraMeta = {
      platforms = [ "aarch64-linux" ];
      #license = lib.licenses.unfreeRedistributableFirmware;
    };
    BL31 = "${final.armTrustedFirmwareRK3399}/bl31.elf";
    filesToInstall = [
      "spl/u-boot-spl.bin"
      "u-boot.itb"
      "idbloader.img"
    ];
  };
}
