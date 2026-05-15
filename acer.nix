{ pkgs, ... }:

{
    boot.kernelModules = ["kvm-amd" "kvm"];
    programs.steam.enable = true;
    services.xserver.videoDrivers = [ "amdgpu" ];

    environment.systemPackages = with pkgs; [
        prismlauncher
        gzdoom
    ];
}
