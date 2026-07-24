{ config, pkgs, lib, unstable, home-manager-src, ... }:

let
	ollama-cuda-bin = pkgs.stdenv.mkDerivation rec {
		pname = "ollama-cuda-bin";
		version = "0.32.3";
		src = pkgs.fetchurl {
			url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tar.zst";
			sha256 = "2597d74fbe654ef6a37db56f771cf37d4a85c6bde4018127874e3927d3113800";
		};
		nativeBuildInputs = [ pkgs.zstd pkgs.makeWrapper ];
		dontUnpack = true;
		installPhase = ''
			runHook preInstall
			mkdir -p $out
			tar --use-compress-program=unzstd -xf $src -C $out
			wrapProgram $out/bin/ollama \
				--set LD_LIBRARY_PATH "/run/current-system/sw/share/nix-ld/lib:/run/opengl-driver/lib:$out/lib/ollama:$out/lib/ollama/cuda_v13:$out/lib/ollama/cuda_v12"
			runHook postInstall
		'';
		meta.mainProgram = "ollama";
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

	networking	= {
		firewall	= {
			interfaces."wlp0s20f3"	= {
				allowedUDPPorts	= [ 53 67 ];
				allowedTCPPorts	= [ 53 ];
			};
		};
	};

	services.xserver.videoDrivers = [ "nvidia" ];

	services.ollama = {
		enable = true;
		package = ollama-cuda-bin;
		loadModels = [ "qwen2.5:7b-instruct" ];
		syncModels = true;
	};

	environment.systemPackages = with pkgs; [
			unstable.stm32cubemx
			stm32flash
			ungoogled-chromium
			gcc-arm-embedded
			mqttx
			thunderbird
			nvtopPackages.nvidia
			android-studio
			rustdesk-flutter
	];

	nixpkgs.config.segger-jlink.acceptLicense = true;
	nixpkgs.config.allowInsecurePredicate = pkg:
	builtins.elem (pkgs.lib.getName pkg) [
		"segger-jlink-qt4"
		"segger-jlink"
	];
}
