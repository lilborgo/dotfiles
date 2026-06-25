{ pkgs, unstable, ... }:

{
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
			lutris
	];

	home-manager.users.fede= { pkgs, ...}:
	{
		home.file.".local/share/lutris/runners/proton/NIXOS_PROTON".source = pkgs.proton-ge-bin.steamcompattool;
	};
}
