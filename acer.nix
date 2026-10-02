{ pkgs, unstable, ... }:

{
	boot.kernelPackages	= pkgs.linuxPackages_latest;
	boot.kernelModules = ["kvm-amd" "kvm"];
	programs.steam = {
		enable = true;
		extraCompatPackages = with pkgs; [
				(pkgs.proton-ge-bin.override { steamDisplayName = "NIXOS-PROTON"; })
				(unstable.proton-ge-bin.overrideAttrs { steamDisplayName = "NIXOS-PROTON-UNSTABLE"; })
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

	#services.restic.backups.acer = {
	#	package = pkgs.writeShellScriptBin "restic" ''
	#		exec ${pkgs.restic}/bin/restic --insecure-tls "$@"
	#	'';
#
	#	# RESTIC_REPOSITORY lives here (not in `repository`) so the rest-server's
	#	# basic-auth password isn't baked into the Nix store / git in plaintext
	#	environmentFile	= "/etc/nixos/secrets/restic-acer-environment";
	#	passwordFile		= "/etc/nixos/secrets/restic-acer-password";
	#	initialize			= true;
#
	#	paths		= [ "/home/fede/Documents" ];
	#	exclude	= [
	#	];
#
	#	timerConfig = {
	#		OnCalendar	= "daily";
	#		Persistent	= true;
	#	};
#
	#	pruneOpts = [
	#		"--keep-daily 7"
	#		"--keep-weekly 4"
	#		"--keep-monthly 6"
	#	];
	#};

	environment.systemPackages = with pkgs; [
			prismlauncher
			gzdoom
			lutris
			nvtopPackages.amd
			restic
	];

	home-manager.users.fede= { pkgs, ...}: {
		home.file.".local/share/lutris/runners/proton/NIXOS_PROTON".source = pkgs.proton-ge-bin.steamcompattool;
	};
}
