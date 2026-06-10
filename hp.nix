{ config, pkgs, lib, ... }:

let
	home-manager-src = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";

	unstable = import (fetchTarball "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz") {
		config.allowUnfree = true;
	};
in
{
		boot.kernelModules = ["kvm-intel" "kvm"];

		hardware.nvidia = {
				modesetting.enable = true;
				open = false;
				nvidiaSettings = true;
				package = config.boot.kernelPackages.nvidiaPackages.stable;
		};

		services.udev.extraRules = ''
				# SEGGER J-Link
				SUBSYSTEM=="usb", ATTR{idVendor}=="1366", ATTR{idProduct}=="0101", MODE="0666", GROUP="plugdev"
		'';

		services.xserver.videoDrivers = [ "nvidia" ];

		environment.systemPackages = with pkgs; [
				unstable.stm32cubemx
				stm32flash
				ungoogled-chromium
				gcc-arm-embedded
				mqttx
				thunderbird
				nvtopPackages.nvidia
				android-studio
				jetbrains.idea
		];

		nixpkgs.config.segger-jlink.acceptLicense = true;
		nixpkgs.config.allowInsecurePredicate = pkg:
		builtins.elem (pkgs.lib.getName pkg) [
			"segger-jlink-qt4"
			"segger-jlink"
		];
}
