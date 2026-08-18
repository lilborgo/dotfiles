{ config, pkgs, lib, unstable, home-manager-src, ... }:

let
	ollama-cuda-bin = pkgs.stdenv.mkDerivation rec {
		pname = "ollama-cuda-bin";
		version = "0.32.14";
		src = pkgs.fetchurl {
			url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tar.zst";
			sha256 = "13yy4y5vwg0wm5wq7vs4s5jlr706cvq88c49gwxanip1f5x92866";
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

	jlink-latest-bin = pkgs.stdenv.mkDerivation rec {
		pname = "jlink-latest-bin";
		version = "964"; # V9.64 -- bump manually, nixpkgs' segger-jlink lags behind upstream
		src = pkgs.fetchurl {
			url = "https://www.segger.com/downloads/jlink/JLink_Linux_V${version}_x86_64.tgz";
			curlOpts = "--data accept_license_agreement=accepted";
			sha256 = "sha256-xxk5mVgA9qRizeo7ORwY8o9EIzclXZtL/GQ0ZiMxEw0=";
		};
		nativeBuildInputs = [ pkgs.makeWrapper ];
		dontUnpack = true;
		installPhase = ''
			runHook preInstall
			mkdir -p $out/opt/segger-jlink $out/bin
			tar xzf $src --strip-components=1 -C $out/opt/segger-jlink
			for exe in $out/opt/segger-jlink/*; do
				[ -f "$exe" ] && [ -x "$exe" ] || continue
				name="$(basename "$exe")"
				makeWrapper "$exe" "$out/bin/$name" \
					--set LD_LIBRARY_PATH "/run/current-system/sw/share/nix-ld/lib:$out/opt/segger-jlink"
			done
			runHook postInstall
		'';
		meta.license = lib.licenses.unfree;
		meta.mainProgram = "JLinkExe";
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
		# ST-LINK/V3
		SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374e", MODE="0666", GROUP="plugdev"
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
			jlink-latest-bin
			nrfutil
			nrf5-sdk
			nrf-udev
			nrfconnect
			opencode
			stlink
	];

	nixpkgs.config.allowUnfree = true;
	nixpkgs.config.segger-jlink.acceptLicense = true;
}
