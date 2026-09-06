{ pkgs, unstable, ... }:

{
	boot.kernelPackages	= pkgs.linuxPackages_latest;
	boot.kernelModules = ["kvm-amd" "kvm"];
	programs.steam = {
		enable = true;
		extraCompatPackages = with pkgs; [
				(pkgs.proton-ge-bin.override { steamDisplayName = "NIXOS-PROTON"; })
		];
	};
	services.xserver.videoDrivers = [ "amdgpu" ];

	services.scx = {
		enable		= true;
		scheduler	= "scx_lavd";
	};

	programs.gamemode.settings = {
		general = {
			renice							= 15;
			desiredgov					= "performance";
			softrealtime				= "auto";
			ioprio							= 0;
			inhibit_screensaver	= 1;
		};
		cpu = {
			park_cores	= "no";
			pin_cores		= "no";
		};
	};

	environment.systemPackages = with pkgs; [
			prismlauncher
			gzdoom
			lutris
			nvtopPackages.amd
	];

	home-manager.users.fede= { pkgs, ...}: {
		home.file.".local/share/lutris/runners/proton/NIXOS_PROTON".source = pkgs.proton-ge-bin.steamcompattool;
	};
}
