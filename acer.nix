{ pkgs, ... }:

let
  home-manager-src = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";

  unstable = import (fetchTarball "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz") {
    config.allowUnfree = true;
  };
in
{
  imports =
  [
    (import "${home-manager-src}/nixos")
  ];

  boot.kernelModules = ["kvm-amd" "kvm"];
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
        (pkgs.proton-ge-bin.override { steamDisplayName = "NIXOS-PROTON"; })
    ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  environment.systemPackages = with pkgs; [
      prismlauncher
      gzdoom
      (lutris.override {
          extraLibraries =  pkgs: [
          ];
      })
  ];

  home-manager.users.fede= { pkgs, ...}:
  {
    home.file.".local/share/lutris/runners/proton/NIXOS_PROTON".source = pkgs.proton-ge-bin.steamcompattool;
  };
}
