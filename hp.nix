{ config, pkgs, ... }:

{
    boot.kernelModules = ["kvm-intel" "kvm"];

    hardware.nvidia = {
        modesetting.enable = true;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    environment.systemPackages = with pkgs; [
        segger-jlink
        stm32cubemx
        stm32flash
    ];

    nixpkgs.config.segger-jlink.acceptLicense = true;
    nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "segger-jlink-qt4"
      "segger-jlink"
    ];
}
