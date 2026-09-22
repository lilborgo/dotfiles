{ config, pkgs, ... }:

let
	home-manager-src	= builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz";
	unstable	= import (fetchTarball "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz") {
		config.allowUnfree	= true;
	};
in
{
	imports	= [
		/etc/nixos/hardware-configuration.nix
		(import "${home-manager-src}/nixos")
		/etc/nixos/custom.nix
	];

	# Pass the let-bound channels down to imported modules (e.g. custom.nix)
	_module.args	= { inherit unstable home-manager-src; };

	system.stateVersion	= "25.11";
	nixpkgs.config.allowUnfree	= true;

	nixpkgs.overlays = [
		(final: prev: {
			openblas =
				if prev.stdenv.hostPlatform.isi686
				then prev.openblas.overrideAttrs (_: { doCheck = false; })
				else prev.openblas;
		})
	];


	#	============================================================
	# BOOT
	#	============================================================

	boot	= {
		tmp.cleanOnBoot	= true;

		loader	= {
			efi.canTouchEfiVariables	= true;
			grub	= {
				enable			= true;
				device			= "nodev";
				efiSupport	= true;
			};
		};
	};


	#	============================================================
	# HARDWARE
	#	============================================================

	hardware	= {
		enableAllFirmware	= true;
		bluetooth.enable	= true;
		graphics	= {
			enable			= true;
			enable32Bit	= true;
		};
	};


	#	============================================================
	# NETWORKING
	#	============================================================

	networking	= {
		hostName							= "nixos";
		networkmanager.enable	= true;
		nftables.enable				= true;
		firewall	= {
			enable					= true;
			allowedTCPPorts	= [22];
			allowedUDPPorts	= [];
			trustedInterfaces	= [ "virbr0" ];
		};
	};


	#	============================================================
	# LOCALISATION
	#	============================================================

	time.timeZone	= "Europe/Rome";
	console.keyMap	= "it2";

	i18n	= {
		defaultLocale				= "it_IT.UTF-8";
		extraLocaleSettings	= {
			LC_ADDRESS				= "it_IT.UTF-8";
			LC_IDENTIFICATION	= "it_IT.UTF-8";
			LC_MEASUREMENT		= "it_IT.UTF-8";
			LC_MONETARY				= "it_IT.UTF-8";
			LC_NAME						= "it_IT.UTF-8";
			LC_NUMERIC				= "it_IT.UTF-8";
			LC_PAPER					= "it_IT.UTF-8";
			LC_TELEPHONE			= "it_IT.UTF-8";
			LC_TIME						= "it_IT.UTF-8";
		};
	};


	#	============================================================
	# USERS
	#	============================================================

	users	= {
		defaultUserShell	= pkgs.zsh;
		groups.plugdev		= {};
		users.fede	= {
			isNormalUser	= true;
			description	= "fede";
			shell				= pkgs.zsh;
			extraGroups	= [
				"disk" "dialout" "docker" "gamemode" "input"
				"kvm" "libvirtd" "lp" "networkmanager"
				"plugdev" "video" "wheel" "wireshark"
			];
		};
	};


	#	============================================================
	# SECURITY
	#	============================================================

	security	= {
		polkit.enable						= true;
		rtkit.enable							= true;
		sudo.wheelNeedsPassword	= false;
	};


	#	============================================================
	# FONTS
	#	============================================================

	fonts.packages	= with pkgs; [
		nerd-fonts.jetbrains-mono
		nerd-fonts.symbols-only
		nerd-fonts.caskaydia-mono
		cascadia-code
		font-awesome
		noto-fonts
	];


	#	============================================================
	# PROGRAMS
	#	============================================================

	programs	= {
		# --- Desktop ---
		dconf.enable				= true;
		gamemode.enable			= true;
		hyprland.enable			= true;
		hyprlock.enable			= true;
		virt-manager.enable	= true;
		xfconf.enable				= true;

		wireshark = {
			enable = true;
			dumpcap.enable = true;
			usbmon.enable = true;
		};

		java = {
			enable = true;
			package = pkgs.jdk21;
		};

		thunar	= {
			enable	= true;
			plugins	= with pkgs; [
				thunar-archive-plugin
				thunar-volman
			];
		};

		# --- Shell ---
		zsh	= {
			enable										= true;
			autosuggestions.enable		= true;
			autosuggestions.strategy	= [ "history" "completion" ];
			syntaxHighlighting.enable	= true;
			zsh-autoenv.enable				= true;
			shellAliases	= {
				switch	= "nh os switch -f '<nixpkgs/nixos>' -- -I nixos-config=/etc/nixos/configuration.nix";
				mem		= "sudo smem -tk -c \"pid user name uss pss rss\"";
				ls			= "eza --icons";
				ll			= "eza -la --icons";
				nixlogs = "journalctl -u nixos-upgrade.service -b -e";
				stress = "stress-ng --cpu 0 --vm 0 --vm-bytes 80% --hdd 2 --hdd-bytes 10G --gpu 0 --timeout 2m --metrics-brief";
				ssh = "kitty +kitten ssh";
			};
			ohMyZsh	= {
				enable	= true;
				theme		= "bira";
				plugins	= [ "git" ];
			};
		};

		# --- nix-ld (dynamic linker for unpatched binaries) ---
		nix-ld	= {
			enable		= true;
			libraries	= with pkgs; [
				# --- core / runtime ---
				stdenv.cc.cc.lib gcc gcc.cc.lib glibc zlib bzip2 xz
				zstd lz4 snappy libffi bash

				# --- crypto / tls / auth ---
				openssl curl libssh2 gnutls libgcrypt libgpg-error
				krb5 cyrus_sasl p11-kit gnupg keyutils libsecret

				# --- X11 / graphics stack ---
				libx11 libxcb libice libsm libxext libxfixes libxrender
				libxrandr libxcomposite libxdamage libxcursor libxi
				libxtst libxinerama libxscrnsaver libxxf86vm libGL libGLU
				libglvnd mesa vulkan-loader libdrm libgbm libepoxy

				# --- wayland ---
				wayland libxkbcommon

				# --- fonts / text ---
				fontconfig freetype harfbuzz fribidi icu

				# --- gtk / theming / a11y ---
				atk cairo pango gtk3 gtk4 gdk-pixbuf glib
				at-spi2-core at-spi2-atk libnotify dbus polkit
				shared-mime-info glibc

				# --- audio ---
				alsa-lib libpulseaudio pipewire SDL2 SDL2_mixer portaudio

				# --- image codecs ---
				libpng libjpeg libtiff giflib libwebp

				# --- misc data / io ---
				sqlite libxml2 libxslt ncurses readline libuuid
				util-linux nghttp2 libidn2 libpsl c-ares libusb1
				pciutils libcap acl attr numactl nspr nss

				# --- misc / debugging ---
				lttng-ust libtorch-bin cups
			];
		};
	};


	#	============================================================
	# SERVICES
	#	============================================================

	# --- Display ---
	services.xserver	= {
		enable					= true;
		excludePackages	= with pkgs; [ xterm ];
		wacom.enable		= true;
		xkb	= {
			layout	= "it";
			variant	= "";
		};
	};
	services.displayManager.ly.enable	= true;
	services.libinput.enable					= true;
	security.pam.services.ly.enableGnomeKeyring	= true;

	# --- Audio ---
	services.pulseaudio.enable	= false;
	services.pipewire	= {
		enable						= true;
		alsa.enable				= true;
		alsa.support32Bit	= true;
		pulse.enable			= true;
	};

	# --- Printing ---
	services.printing	= {
		enable	= true;
		drivers	= with pkgs; [ gutenprint gutenprintBin ];
	};
	services.avahi	= {
		enable				= true;
		nssmdns4			= true;
		openFirewall	= true;
	};

	# --- Bluetooth ---
	services.blueman.enable	= true;

	# --- Desktop utilities ---
	services.flatpak.enable		= true;
	services.gnome.gnome-keyring.enable	= true;
	services.gvfs.enable		= true;
	services.playerctld.enable	= true;
	services.udisks2.enable		= true;

	# --- Virtualisation guests ---
	services.qemuGuest.enable			= true;
	services.spice-vdagentd.enable	= true;

	# --- Misc ---
	systemd.services.NetworkManager-wait-online.enable	= false;
	systemd.tmpfiles.rules	= [
		"L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
		"L+ /bin/chmod - - - - ${pkgs.coreutils}/bin/chmod"
	];
	services.openssh = {
		enable = true;
		ports = [ 22 ];
		settings = {
			PasswordAuthentication = true;
			AllowUsers = ["fede"];
			UseDns = true;
			X11Forwarding = false;
			PermitRootLogin = "no";
		};
	};


	#	============================================================
	# VIRTUALISATION
	#	============================================================

	virtualisation	= {
		docker	= {
			enable				= true;
			enableOnBoot	= false;
		};
		libvirtd	= {
			enable	= true;
			qemu	= {
				package			= pkgs.qemu_kvm;
				runAsRoot		= true;
				swtpm.enable	= true;
			};
		};
		spiceUSBRedirection.enable	= true;
	};


	#	============================================================
	# XDG PORTALS
	#	============================================================

	xdg.portal	= {
		enable				= true;
		config	= {
			common.default		= [ "gtk" ];
			hyprland.default	= [ "hyprland" "gtk" ];
		};
		extraPortals	= with pkgs; [
			xdg-desktop-portal-gtk
			xdg-desktop-portal-hyprland
		];
	};


	#	============================================================
	# QT THEMING
	#	============================================================

	qt	= {
		enable				= true;
		platformTheme	= "gtk2";
		style					= "gtk2";
	};


	#	============================================================
	# ENVIRONMENT
	#	============================================================

	environment.sessionVariables	= {
		NIXOS_OZONE_WL							= "1";
		QT_AUTO_SCREEN_SCALE_FACTOR	= "1";
		QT_SCALE_FACTOR							= "1";
		LIBTORCH = "${pkgs.libtorch-bin}";
		LIBTORCH_INCLUDE = "${pkgs.libtorch-bin.dev}";
	};

	environment.systemPackages	= with pkgs; [
		# --- Terminal & shell utilities ---
		bash bat btop busybox eza fd file fzf htop gdu
		ripgrep smem tree wget kitty exfat srecord
		poppler-utils glib sshpass dig
		curl duf lazyjournal hexyl lsof tealdeer tmux rsync
		watch parallel mosh stress-ng peaclock

		# --- Build tools & compilers ---
		cargo clang clang-tools cmake gcc gcc.cc.lib glibc
		gnumake rustc binutils pkg-config gtk3.dev glib.dev

		# --- Development ---
		gh git nano micro
		(python3.withPackages (ps: with ps; [
			paho-mqtt pypdf torch torchvision matplotlib
			west tkinter pyserial pyelftools pyyaml pykwalify
			packaging patool psutil pylink-square requests
			semver tqdm reuse anytree intelhex colorama
			cryptography cbor pyocd jsonschema canopen
			diffusers transformers accelerate safetensors
			sentencepiece huggingface-hub pillow protobuf
			plotly
		]))
		vscode unstable.claude-code probe-rs-tools
		gnirehtet tio jetbrains.idea libtorch-bin dbeaver-bin
		nodejs dtc wireshark pyocd
		jq yq-go delta lazygit sqlite hyperfine tokei
		gdb strace ltrace openssl bun opencode

		# --- Networking & debugging ---
		tcpdump socat netcat pciutils usbutils

		# --- Nix tools ---
		fastfetch nh nixfmt nvd nix-output-monitor

		# --- Hyprland & desktop shell ---
		hyprland hypridle hyprshot hyprsunset
		lxsession rofi hyprpaper waybar

		# --- GUI applications ---
		file-roller filezilla freefilesync
		gparted impression libqalculate libreoffice-qt localsend
		loupe pavucontrol styluslabs-write-bin
		tor-browser vlc papirus-folders parted

		# --- Browser ---
		firefox google-chrome

		# --- Wayland & clipboard ---
		cliphist wev wl-clipboard

		# --- Networking ---
		iproute2 networkmanager networkmanagerapplet nmap wireguard-tools posting

		# --- Bluetooth ---
		blueman bluez

		# --- Hardware & system ---
		brightnessctl libinput libnotify libwacom procps
		smartmontools vulkan-tools

		# --- Theming ---
		adwaita-qt adwaita-qt6 gtk2 gtk3 gtk4

		# --- Virtualisation ---
		spice spice-gtk usbredir virt-manager virt-viewer virtiofsd

		# --- Wine & gaming ---
		steam-run wine64

		# --- Android ---
		android-tools scrcpy

		# --- Compression ---
		bzip2 gnutar gzip p7zip unzip xz zip zstd

		# --- Printing ---
		cups-filters

		# --- File sharing ---
		cifs-utils samba
	];


	#	============================================================
	# NIX
	#	============================================================

	nix	= {
		gc	= {
			automatic	= true;
			dates			= "weekly";
			options		= "--delete-older-than 14d";
		};
		settings	= {
			auto-optimise-store		= true;
			cores									= 0;
			experimental-features	= [ "nix-command" "flakes" ];
			max-jobs							= "auto";
		};
	};

	system.autoUpgrade	= {
		allowReboot					= false;
		dates								= "daily";
		enable								= true;
		randomizedDelaySec		= "45min";
		runGarbageCollection	= true;
	};


	#	============================================================
	# HOME MANAGER — fede
	#	============================================================

	home-manager.useGlobalPkgs	= true;

	home-manager.users.fede	= { pkgs, ... }: {
		home.stateVersion	= "23.11";


		# --- MangoHud ---
		programs.mangohud	= {
			enable		= true;
			settings	= {
				# Display
				position					= "top-left";
				background_alpha	= 0.5;
				font_size				= 24;
				toggle_hud				= "Shift_R+F12";
				# Metrics
				fps					= true;
				frame_timing	= true;
				cpu_stats		= true;
				cpu_temp			= true;
				gpu_stats		= true;
				gpu_temp			= true;
				gpu_power		= true;
				ram					= true;
				vram					= true;
			};
		};


		home.pointerCursor	= {
			gtk.enable				= true;
			hyprcursor.enable	= true;
			name							= "phinger-cursors-dark";
			package						= pkgs.phinger-cursors;
			size							= 24;
		};

		gtk	= {
			enable						= true;
			cursorTheme.name	= "phinger-cursors-dark";
			iconTheme	= {
				name		= "Papirus-Dark";
    			package = pkgs.papirus-icon-theme.override { color = "red"; };
			};
			theme	= {
				name		= "Graphite-teal-Dark";
				package	= pkgs.graphite-gtk-theme.override {
					themeVariants	= [ "teal" ];
					colorVariants	= [ "dark" ];
					tweaks				= [ "darker" ];
				};
			};
			gtk4.theme	= {
				name		= "Graphite-teal-Dark";
				package	= pkgs.graphite-gtk-theme.override {
					themeVariants	= [ "teal" ];
					colorVariants	= [ "dark" ];
					tweaks				= [ "darker" ];
				};
			};
		};


		# --- XDG user directories ---
		xdg.userDirs	= {
			enable							= true;
			createDirectories		= true;
			setSessionVariables	= true;
		};


		# --- XDG desktop entries ---
		xdg.desktopEntries	= {
			code	= {
				name				= "Visual Studio Code";
				exec				= "env LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib code %F";
				icon				= "vscode";
				terminal		= false;
				categories	= [ "Development" "IDE" "TextEditor" "Utility" ];
				mimeType		= [ "application/x-code-workspace" ];
			};
			micro	= {
				name				= "Micro";
				exec				= "kitty -e micro %F";
				terminal		= false;
				categories	= [ "TextEditor" "Utility" ];
				mimeType		= [ "text/plain" ];
			};
			nixwiki	= {
				name				= "Nixos Wiki";
				exec				= "xdg-open https://search.nixos.org/";
				icon				= "nix-snowflake";
				terminal		= false;
				categories	= [ "Utility" ];
			};
			nmtui	= {
				name				= "nmtui";
				exec				= "kitty -e nmtui";
				terminal		= false;
				categories	= [ "Network" ];
			};
			spotify	= {
				name				= "Spotify";
				exec				= "xdg-open https://open.spotify.com/";
				icon				= "spotify";
				terminal		= false;
				categories	= [ "Music" ];
			};
			#	yazi ships Terminal=true, which launchers can't open reliably outside a terminal
			yazi	= {
				name				= "Yazi File Manager";
				exec				= "kitty -e yazi %f";
				icon				= "yazi";
				terminal		= false;
				categories	= [ "System" "FileManager" "FileTools" ];
				mimeType		= [ "inode/directory" ];
			};
		};


		# --- MIME associations ---
		xdg.mimeApps	= {
			enable							= true;
			defaultApplications	= {
				# Browser
				"application/x-extension-htm"				= "firefox.desktop";
				"application/x-extension-html"				= "firefox.desktop";
				"application/x-extension-xhtml"			= "firefox.desktop";
				"application/xhtml+xml"							= "firefox.desktop";
				"text/html"													= "firefox.desktop";
				"x-scheme-handler/ftp"								= "firefox.desktop";
				"x-scheme-handler/http"							= "firefox.desktop";
				"x-scheme-handler/https"							= "firefox.desktop";
				"x-scheme-handler/mailto"						= "firefox.desktop";

				# File manager
				"inode/directory"										= "yazi.desktop";

				# PDF
				"application/pdf"										= "firefox.desktop";
				"application/x-bzpdf"								= "firefox.desktop";
				"application/x-gzpdf"								= "firefox.desktop";
				"application/x-pdf"									= "firefox.desktop";

				# Images
				"image/avif"													= "org.gnome.Loupe.desktop";
				"image/bmp"													= "org.gnome.Loupe.desktop";
				"image/gif"													= "org.gnome.Loupe.desktop";
				"image/heic"													= "org.gnome.Loupe.desktop";
				"image/jpeg"													= "org.gnome.Loupe.desktop";
				"image/jpg"													= "org.gnome.Loupe.desktop";
				"image/png"													= "org.gnome.Loupe.desktop";
				"image/svg+xml"											= "org.gnome.Loupe.desktop";
				"image/tiff"													= "org.gnome.Loupe.desktop";
				"image/webp"													= "org.gnome.Loupe.desktop";
				"image/x-portable-pixmap"						= "org.gnome.Loupe.desktop";

				# Video
				"video/3gpp"													= "vlc.desktop";
				"video/avi"													= "vlc.desktop";
				"video/mp4"													= "vlc.desktop";
				"video/mpeg"													= "vlc.desktop";
				"video/ogg"													= "vlc.desktop";
				"video/quicktime"										= "vlc.desktop";
				"video/webm"													= "vlc.desktop";
				"video/x-flv"												= "vlc.desktop";
				"video/x-matroska"										= "vlc.desktop";
				"video/x-ms-wmv"											= "vlc.desktop";
				"video/x-msvideo"										= "vlc.desktop";

				# Audio
				"audio/aac"													= "vlc.desktop";
				"audio/flac"													= "vlc.desktop";
				"audio/mp4"													= "vlc.desktop";
				"audio/mpeg"													= "vlc.desktop";
				"audio/ogg"													= "vlc.desktop";
				"audio/opus"													= "vlc.desktop";
				"audio/wav"													= "vlc.desktop";
				"audio/webm"													= "vlc.desktop";
				"audio/x-m4a"												= "vlc.desktop";
				"audio/x-wav"												= "vlc.desktop";

				# Text editor
				"application/javascript"							= "micro.desktop";
				"application/json"										= "micro.desktop";
				"application/toml"										= "micro.desktop";
				"application/typescript"							= "micro.desktop";
				"application/x-desktop"							= "micro.desktop";
				"application/x-sh"										= "micro.desktop";
				"application/x-shellscript"					= "micro.desktop";
				"application/x-yaml"									= "micro.desktop";
				"application/yaml"										= "micro.desktop";
				"application/xml"										= "micro.desktop";
				"audio/vnd.dts"											= "micro.desktop";
				"text/css"														= "micro.desktop";
				"text/csv"														= "micro.desktop";
				"text/markdown"											= "micro.desktop";
				"text/plain"													= "micro.desktop";
				"text/x-asm"													= "micro.desktop";
				"text/x-c"														= "micro.desktop";
				"text/x-c++hdr"											= "micro.desktop";
				"text/x-c++src"											= "micro.desktop";
				"text/x-chdr"												= "micro.desktop";
				"text/x-csrc"												= "micro.desktop";
				"text/x-diff"												= "micro.desktop";
				"text/x-dockerfile"									= "micro.desktop";
				"text/x-go"													= "micro.desktop";
				"text/x-java-source"									= "micro.desktop";
				"text/x-javascript"									= "micro.desktop";
				"text/x-log"													= "micro.desktop";
				"text/x-lua"													= "micro.desktop";
				"text/x-makefile"										= "micro.desktop";
				"text/x-nix"													= "micro.desktop";
				"text/x-patch"												= "micro.desktop";
				"text/x-perl"												= "micro.desktop";
				"text/x-python"											= "micro.desktop";
				"text/x-readme"											= "micro.desktop";
				"text/x-ruby"												= "micro.desktop";
				"text/x-rust"												= "micro.desktop";
				"text/x-script"											= "micro.desktop";
				"text/x-sh"													= "micro.desktop";
				"text/x-sql"													= "micro.desktop";
				"text/x-toml"												= "micro.desktop";
				"text/x-typescript"									= "micro.desktop";
				"text/xml"														= "micro.desktop";

				# IDE
				"application/x-code-workspace"				= "vscode.desktop";

				# Archives
				"application/x-7z-compressed"				= "org.gnome.FileRoller.desktop";
				"application/x-bzip2-compressed-tar"	= "org.gnome.FileRoller.desktop";
				"application/x-compressed-tar"				= "org.gnome.FileRoller.desktop";
				"application/x-rar"									= "org.gnome.FileRoller.desktop";
				"application/x-rar-compressed"				= "org.gnome.FileRoller.desktop";
				"application/x-tar"									= "org.gnome.FileRoller.desktop";
				"application/x-xz-compressed-tar"		= "org.gnome.FileRoller.desktop";
				"application/zip"										= "org.gnome.FileRoller.desktop";

				# Torrents
				"application/x-bittorrent"						= "vlc.desktop";
			};
		};


		# --- Systemd user targets ---
		systemd.user.targets.hyprland-session	= {
			Unit.Description	= "Hyprland compositor session";
		};


		# --- Systemd user services ---
		systemd.user.services	=
			let
				graphicalService	= desc: cmd: extra: {
					Unit		= { Description	= desc; PartOf	= [ "hyprland-session.target" ]; After	= [ "hyprland-session.target" ]; };
					Service	= { ExecStart	= cmd; Restart	= "always"; RestartSec	= 1; } // extra;
					Install	= { WantedBy	= [ "hyprland-session.target" ]; };
				};
			in {
				hyprsunset		= graphicalService "Hyprsunset blue light filter" "${pkgs.hyprsunset}/bin/hyprsunset" {};
				waybar			= graphicalService "Waybar panel" "${pkgs.waybar}/bin/waybar" {};
				lxpolkit		= graphicalService "lxpolkit" "${pkgs.lxsession}/bin/lxpolkit" {};
				hypridle		= graphicalService "Hyprland idle" "${pkgs.hypridle}/bin/hypridle" {};
				hyprpaper		= graphicalService "Hyprland wallpaper" "${pkgs.hyprpaper}/bin/hyprpaper" {};
				nm-applet		= graphicalService "NetworkManager applet" "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator" {};
				blueman-applet	= graphicalService "Blueman applet" "${pkgs.blueman}/bin/blueman-applet" {};
				dunst			= {
					Unit.PartOf			= [ "hyprland-session.target" ];
					Unit.After			= [ "hyprland-session.target" ];
					Install.WantedBy	= [ "hyprland-session.target" ];
				};
			};

		# --- Notifications (dunst) ---
		services.dunst	= {
			enable	= true;
			settings	= {
				global	= {
					monitor			= 0;
					follow			= "mouse";
					origin			= "top-right";
					offset			= "8x10";
					width				= 420;
					height			= 300;
					notification_limit	= 6;
					gap_size		= 8;
					indicate_hidden	= true;
					shrink			= false;

					transparency	= 10;
					corner_radius	= 12;
					frame_width		= 1;
					separator_height	= 2;
					separator_color	= "frame";
					padding			= 12;
					horizontal_padding	= 14;
					text_icon_padding	= 8;
					line_height		= 0;

					progress_bar			= true;
					progress_bar_height		= 10;
					progress_bar_frame_width	= 1;
					progress_bar_min_width	= 180;
					progress_bar_max_width	= 396;
					progress_bar_corner_radius	= 5;
					highlight		= "#22c9c0";

					font			= "JetBrainsMono Nerd Font Propo 11";
					markup			= "full";
					format			= "<b>%s</b>\\n%b";
					alignment		= "left";
					vertical_alignment	= "center";
					word_wrap		= true;
					ellipsize		= "middle";
					ignore_newline	= false;
					show_age_threshold	= 60;
					stack_duplicates	= true;
					hide_duplicate_count	= false;
					show_indicators	= true;

					enable_recursive_icon_lookup	= true;
					icon_theme		= "Papirus-Dark";
					icon_position	= "left";
					min_icon_size	= 16;
					max_icon_size	= 48;

					sticky_history	= true;
					history_length	= 40;

					sort			= true;
					idle_threshold	= 0;
					title			= "Dunst";
					class			= "Dunst";
					ignore_dbusclose	= false;
					force_xwayland	= false;
					browser			= "${pkgs.xdg-utils}/bin/xdg-open";

					# Action / context menu via the system's themed rofi
					dmenu			= "rofi -dmenu -theme /home/fede/.config/rofi/themes/clipboard.rasi -p Notification";

					mouse_left_click	= "do_action, close_current";
					mouse_middle_click	= "close_all";
					mouse_right_click	= "context, close_current";
				};

				urgency_low	= {
					timeout		= 2;
					background	= "#0c0f10e6";
					foreground	= "#6f8a86";
					frame_color	= "#22c9c0";
				};

				urgency_normal	= {
					timeout		= 3;
					background	= "#0c0f10e6";
					foreground	= "#d3e4df";
					frame_color	= "#22c9c0";
				};

				urgency_critical	= {
					timeout		= 0;
					background	= "#0c0f10f2";
					foreground	= "#d3e4df";
					frame_color	= "#ec3f5d";
				};
			};
		};

		programs.yazi	= {
			enable								= true;
			enableZshIntegration	= true;

			extraPackages	= with pkgs; [
				glow
				rich-cli
				unar
				mediainfo
				imagemagick
				ouch
				p7zip
				lazygit
				dragon-drop
				wl-clipboard
				trash-cli
				fd ripgrep fzf
				gvfs
				glib
				udisks
				util-linux
			];

			plugins	= with pkgs.yaziPlugins; {
				inherit git githead full-border mime-ext
					glow rich-preview lsar mediainfo
					smart-enter smart-filter smart-paste jump-to-char
					chmod sudo diff compress ouch bookmarks lazygit drag
					toggle-pane restore wl-clipboard gvfs mount;
			};

			settings	= {
				mgr	= {
					show_hidden			= true;
					sort_by					= "natural";
					sort_dir_first	= true;
					linemode				= "size";
					ratio						= [ 1 3 4 ];
				};

				preview	= {
					max_width		= 1200;
					max_height	= 1200;
				};

				#	micro is the editor for everything text-shaped
				opener	= {
					edit	= [ { run = ''micro "$@"''; block = true; desc = "micro"; } ];
				};

				plugin	= {
					prepend_fetchers	= [
						{ url = "*";  run = "git"; group = "git"; }
						{ url = "*/"; run = "git"; group = "git"; }
						#	mime type from the extension database instead of file(1) — faster
						{ url = "local://*";  run = "mime-ext.local";  prio = "high"; group = "mime"; }
						{ url = "remote://*"; run = "mime-ext.remote"; prio = "high"; group = "mime"; }
					];

					prepend_previewers	= [
						{ url = "*.md";    run = "glow"; }
						{ url = "*.csv";   run = "rich-preview"; }
						{ url = "*.json";  run = "rich-preview"; }
						{ url = "*.rst";   run = "rich-preview"; }
						{ url = "*.ipynb"; run = "rich-preview"; }
						{ mime = "application/{,g}zip";              run = "lsar"; }
						{ mime = "application/{tar,bzip*,7z*,xz,rar}"; run = "lsar"; }
						{ mime = "{audio,video}/*"; run = "mediainfo"; }
					];
				};
			};

			initLua	= ''
				require("git"):setup()
				require("githead"):setup()
				require("full-border"):setup()
				require("mime-ext.local"):setup { fallback_file1 = true }
				require("bookmarks"):setup({ last_directory = { enable = true }, persist = "all" })
				require("gvfs"):setup({ input_position = { "center", y = 0, w = 60 } })
			'';

			keymap	= {
				mgr.keymap	= [
					#	movement: w up, s down (arrows still work)
					{ on = "w";           run = "arrow prev"; desc = "Move up"; }
					{ on = "s";           run = "arrow next"; desc = "Move down"; }
					{ on = "<Up>";        run = "arrow -1"; desc = "Move up"; }
					{ on = "<Down>";      run = "arrow 1"; desc = "Move down"; }

					#	open / back: d goes in or opens, a goes up
					{ on = "d";           run = "plugin smart-enter"; desc = "Enter the child directory, or open the file"; }
					{ on = "a";           run = "leave"; desc = "Go to the parent directory"; }
					{ on = "<Enter>";     run = "plugin smart-enter"; desc = "Enter the child directory, or open the file"; }
					{ on = "<Backspace>"; run = "leave"; desc = "Go to the parent directory"; }

					#	clipboard: c copy, x cut, v paste
					{ on = "c"; run = "yank"; desc = "Copy selected files"; }
					{ on = "x"; run = "yank --cut"; desc = "Cut selected files"; }
					{ on = "v"; run = "plugin smart-paste"; desc = "Paste into the hovered directory"; }

					#	create / rename
					{ on = "n"; run = "create"; desc = "Create a file (end with / for a folder)"; }
					{ on = "r"; run = "rename --cursor=before_ext"; desc = "Rename selected file(s)"; }

					#	delete: z to trash, Z permanently
					{ on = "z"; run = "remove"; desc = "Move selected files to trash"; }
					{ on = "Z"; run = "remove --permanently"; desc = "Permanently delete selected files"; }

					#	search: f filters this folder, F searches subfolders by name, J jumps to a char
					{ on = "f"; run = "plugin smart-filter"; desc = "Quick filter in this folder"; }
					{ on = "F"; run = "search --via=fd"; desc = "Search files by name in subfolders"; }
					{ on = "J"; run = "plugin jump-to-char"; desc = "Jump to next file starting with a char"; }

					#	tabs: 1-9 switch (yazi default), t new, R rename
					{ on = "t"; run = "tab_create --current"; desc = "New tab in the current folder"; }
					{ on = "R"; run = "tab_rename --interactive"; desc = "Rename the current tab"; }

					#	terminal & git
					{ on = "T"; run = "shell --orphan -- kitty"; desc = "Open kitty in the current folder"; }
					{ on = "g"; run = "plugin lazygit"; desc = "Open lazygit"; }

					#	selection & tasks
					{ on = "V"; run = "visual_mode"; desc = "Visual selection mode"; }
					{ on = "W"; run = "tasks:show"; desc = "Show task manager"; }

					#	e: file tools
					{ on = [ "e" "c" ]; run = "plugin compress"; desc = "Compress selected files"; }
					{ on = [ "e" "x" ]; run = "shell --block -- ouch d -y %h"; desc = "Extract hovered archive here"; }
					{ on = [ "e" "p" ]; run = "plugin chmod"; desc = "chmod selected files"; }
					{ on = [ "e" "u" ]; run = "plugin restore"; desc = "Restore last trashed files"; }

					#	h: go to
					{ on = [ "h" "t" ];       run = "arrow top"; desc = "Go to top"; }
					{ on = [ "h" "h" ];       run = "cd ~"; desc = "Go home"; }
					{ on = [ "h" "c" ];       run = "cd ~/.config"; desc = "Go ~/.config"; }
					{ on = [ "h" "d" ];       run = "cd ~/Documents"; desc = "Go ~/Documents"; }
					{ on = [ "h" "<Space>" ]; run = "cd --interactive"; desc = "Go to a typed path"; }
					{ on = [ "h" "f" ];       run = "follow"; desc = "Follow hovered symlink"; }

					#	y: copy path to clipboard
					{ on = [ "y" "p" ]; run = "copy path"; desc = "Copy full path"; }
					{ on = [ "y" "d" ]; run = "copy dirname"; desc = "Copy folder path"; }
					{ on = [ "y" "f" ]; run = "copy filename"; desc = "Copy filename"; }
					{ on = [ "y" "n" ]; run = "copy name_without_ext"; desc = "Copy filename without extension"; }

					#	m: mounts (gvfs)
					{ on = [ "m" "m" ]; run = "plugin gvfs -- select-then-mount --jump"; desc = "Mount a device and jump to it"; }
					{ on = [ "m" "u" ]; run = "plugin gvfs -- select-then-unmount --eject"; desc = "Unmount / eject a device"; }
					{ on = [ "m" "U" ]; run = "plugin gvfs -- select-then-unmount --eject --force"; desc = "Force unmount / eject a device"; }
					{ on = [ "m" "r" ]; run = "plugin gvfs -- remount-current-cwd-device"; desc = "Remount the device under cwd"; }
					{ on = [ "m" "j" ]; run = "plugin mount"; desc = "Disk manager: all drives, mounted or not"; }
					{ on = [ "m" "J" ]; run = "plugin gvfs -- jump-to-device"; desc = "Jump to a mounted phone / network share"; }
					{ on = [ "m" "a" ]; run = "plugin gvfs -- jump-back-prev-cwd"; desc = "Jump back to where you were"; }
					{ on = [ "m" "n" ]; run = "plugin gvfs -- add-mount"; desc = "Add a network mount (SMB/SFTP/FTP)"; }
					{ on = [ "m" "e" ]; run = "plugin gvfs -- edit-mount"; desc = "Edit a saved network mount"; }
					{ on = [ "m" "z" ]; run = "plugin gvfs -- remove-mount"; desc = "Remove a saved network mount"; }

					#	other plugins
					{ on = "<Tab>"; run = "plugin toggle-pane max-preview"; desc = "Maximise the preview"; }
					{ on = "!";     run = "plugin sudo"; desc = "Run a command as root"; }
					{ on = "<C-d>"; run = "plugin diff"; desc = "Diff the selected file against hovered"; }
					{ on = "<C-y>"; run = "plugin wl-clipboard"; desc = "Copy selected files to the clipboard"; }
					{ on = "<C-n>"; run = "plugin drag"; desc = "Drag and drop selected files"; }

					#	l: linemode (moved off the m menu)
					{ on = [ "l" "s" ]; run = "linemode size"; desc = "Linemode: size"; }
					{ on = [ "l" "p" ]; run = "linemode permissions"; desc = "Linemode: permissions"; }
					{ on = [ "l" "b" ]; run = "linemode btime"; desc = "Linemode: btime"; }
					{ on = [ "l" "m" ]; run = "linemode mtime"; desc = "Linemode: mtime"; }
					{ on = [ "l" "o" ]; run = "linemode owner"; desc = "Linemode: owner"; }
					{ on = [ "l" "n" ]; run = "linemode none"; desc = "Linemode: none"; }

					#	--- yazi 26.5.6 defaults ---
					#	this is a full `keymap`, not `prepend_keymap`: presets are replaced,
					#	so unwanted default chords (linemode on m, goto on g, ...) no longer appear
					{ on = "<Esc>"; run = "escape"; desc = "Exit visual mode, clear selection, or cancel search"; }
					{ on = "<C-[>"; run = "escape"; desc = "Exit visual mode, clear selection, or cancel search"; }
					{ on = "q"; run = "quit"; desc = "Quit the process"; }
					{ on = "Q"; run = "quit --no-cwd-file"; desc = "Quit without outputting cwd-file"; }
					{ on = "<C-c>"; run = "close"; desc = "Close the current tab, or quit if it's last"; }
					{ on = "<C-z>"; run = "suspend"; desc = "Suspend the process"; }
					{ on = "k"; run = "arrow prev"; desc = "Previous file"; }
					{ on = "j"; run = "arrow next"; desc = "Next file"; }
					{ on = "<C-u>"; run = "arrow -50%"; desc = "Move cursor up half page"; }
					{ on = "<C-b>"; run = "arrow -100%"; desc = "Move cursor up one page"; }
					{ on = "<C-f>"; run = "arrow 100%"; desc = "Move cursor down one page"; }
					{ on = "<S-PageUp>"; run = "arrow -50%"; desc = "Move cursor up half page"; }
					{ on = "<S-PageDown>"; run = "arrow 50%"; desc = "Move cursor down half page"; }
					{ on = "<PageUp>"; run = "arrow -100%"; desc = "Move cursor up one page"; }
					{ on = "<PageDown>"; run = "arrow 100%"; desc = "Move cursor down one page"; }
					{ on = "G"; run = "arrow bot"; desc = "Go to bottom"; }
					{ on = "<Left>"; run = "leave"; desc = "Back to the parent directory"; }
					{ on = "<Right>"; run = "enter"; desc = "Enter the child directory"; }
					{ on = "H"; run = "back"; desc = "Back to previous directory"; }
					{ on = "L"; run = "forward"; desc = "Forward to next directory"; }
					{ on = "<Space>"; run = [ "toggle" "arrow 1" ]; desc = "Toggle the current selection state"; }
					{ on = "<C-a>"; run = "toggle_all --state=on"; desc = "Select all files"; }
					{ on = "<C-r>"; run = "toggle_all"; desc = "Invert selection of all files"; }
					{ on = "K"; run = "seek -5"; desc = "Seek up 5 units in the preview"; }
					{ on = "o"; run = "open"; desc = "Open selected files"; }
					{ on = "O"; run = "open --interactive"; desc = "Open selected files interactively"; }
					{ on = "<S-Enter>"; run = "open --interactive"; desc = "Open selected files interactively"; }
					{ on = "p"; run = "paste"; desc = "Paste yanked files"; }
					{ on = "P"; run = "paste --force"; desc = "Paste yanked files (overwrite if the destination exists)"; }
					{ on = "-"; run = "link"; desc = "Symlink the absolute path of yanked files"; }
					{ on = "_"; run = "link --relative"; desc = "Symlink the relative path of yanked files"; }
					{ on = "<C-->"; run = "hardlink"; desc = "Hardlink yanked files"; }
					{ on = "Y"; run = "unyank"; desc = "Cancel the yank status"; }
					{ on = "X"; run = "unyank"; desc = "Cancel the yank status"; }
					{ on = "D"; run = "remove --permanently"; desc = "Permanently delete selected files"; }
					{ on = ";"; run = "shell --interactive"; desc = "Run a shell command"; }
					{ on = ":"; run = "shell --block --interactive"; desc = "Run a shell command (block until finishes)"; }
					{ on = "."; run = "hidden toggle"; desc = "Toggle the visibility of hidden files"; }
					{ on = "S"; run = "search --via=rg"; desc = "Search files by content via ripgrep"; }
					{ on = "<C-s>"; run = "escape --search"; desc = "Cancel the ongoing search"; }
					{ on = "/"; run = "find --smart"; desc = "Find next file"; }
					{ on = "?"; run = "find --previous --smart"; desc = "Find previous file"; }
					{ on = "N"; run = "find_arrow --previous"; desc = "Previous found"; }
					{ on = [ "," "m" ]; run = [ "sort mtime --reverse=no" "linemode mtime" ]; desc = "Sort by modified time"; }
					{ on = [ "," "M" ]; run = [ "sort mtime --reverse=yes" "linemode mtime" ]; desc = "Sort by modified time (reverse)"; }
					{ on = [ "," "b" ]; run = [ "sort btime --reverse=no" "linemode btime" ]; desc = "Sort by birth time"; }
					{ on = [ "," "B" ]; run = [ "sort btime --reverse=yes" "linemode btime" ]; desc = "Sort by birth time (reverse)"; }
					{ on = [ "," "e" ]; run = "sort extension --reverse=no"; desc = "Sort by extension"; }
					{ on = [ "," "E" ]; run = "sort extension --reverse=yes"; desc = "Sort by extension (reverse)"; }
					{ on = [ "," "a" ]; run = "sort alphabetical --reverse=no"; desc = "Sort alphabetically"; }
					{ on = [ "," "A" ]; run = "sort alphabetical --reverse=yes"; desc = "Sort alphabetically (reverse)"; }
					{ on = [ "," "n" ]; run = "sort natural --reverse=no"; desc = "Sort naturally"; }
					{ on = [ "," "N" ]; run = "sort natural --reverse=yes"; desc = "Sort naturally (reverse)"; }
					{ on = [ "," "s" ]; run = [ "sort size --reverse=no" "linemode size" ]; desc = "Sort by size"; }
					{ on = [ "," "S" ]; run = [ "sort size --reverse=yes" "linemode size" ]; desc = "Sort by size (reverse)"; }
					{ on = [ "," "r" ]; run = "sort random --reverse=no"; desc = "Sort randomly"; }
					{ on = "1"; run = "tab_switch 0"; desc = "Switch to first tab"; }
					{ on = "2"; run = "tab_switch 1"; desc = "Switch to second tab"; }
					{ on = "3"; run = "tab_switch 2"; desc = "Switch to third tab"; }
					{ on = "4"; run = "tab_switch 3"; desc = "Switch to fourth tab"; }
					{ on = "5"; run = "tab_switch 4"; desc = "Switch to fifth tab"; }
					{ on = "6"; run = "tab_switch 5"; desc = "Switch to sixth tab"; }
					{ on = "7"; run = "tab_switch 6"; desc = "Switch to seventh tab"; }
					{ on = "8"; run = "tab_switch 7"; desc = "Switch to eighth tab"; }
					{ on = "9"; run = "tab_switch 8"; desc = "Switch to ninth tab"; }
					{ on = "["; run = "tab_switch -1 --relative"; desc = "Switch to previous tab"; }
					{ on = "]"; run = "tab_switch 1 --relative"; desc = "Switch to next tab"; }
					{ on = "{"; run = "tab_swap -1"; desc = "Swap current tab with previous tab"; }
					{ on = "}"; run = "tab_swap 1"; desc = "Swap current tab with next tab"; }
					{ on = "~"; run = "help"; desc = "Open help"; }
					{ on = "<F1>"; run = "help"; desc = "Open help"; }
				];
			};
		};


		programs.kitty = {
			enable = true;

			themeFile = null;

			font = {
				name = "JetBrainsMono Nerd Font";
			};
			
			shellIntegration = {
				enableZshIntegration = true;
			};

			settings = {
				enabled_layouts = "tall, fat, grid, splits, stack";
				enable_audio_bell = false;
				visual_bell_duration = "0.0";
				window_alert_on_bell = false;
				confirm_os_window_close = 0;
				# Window settings
				window_padding_width = 10;
				hide_window_decorations = false;
				
				# Cursor settings
				cursor_shape = "underline";
				cursor_blink_interval = "0.5";

				# Selection
				copy_on_select = "yes";

				# --- Stile Tab (Ispirato a Konsole) ---
				tab_bar_edge = "bottom";            # Barra in basso come Konsole
				tab_bar_style = "separator";         # O "slant" per schede sagomate
				tab_powerline_style = "slanted";
				active_tab_font_style = "bold";
				inactive_tab_font_style = "normal";

				# Colorazione Tab (coerente con la tua palette)
				active_tab_foreground   = "#0c0f10";
				active_tab_background   = "#22c9c0"; # Tab attivo in evidenza
				inactive_tab_foreground = "#a9bdb8";
				inactive_tab_background = "#1b2122"; # Tab inattivi scuri
				tab_bar_background      = "#0c0f10";

				# Colors - Primary
				background = "#0c0f10";
				foreground = "#d3e4df";
				cursor = "#22c9c0";
				selection_background = "#2a3534";
				selection_foreground = "none";

				# Colors - Normal
				color0 = "#1b2122";
				color1 = "#ec3f5d";
				color2 = "#46c08a";
				color3 = "#f3c44b";
				color4 = "#22c9c0";
				color5 = "#e0588f";
				color6 = "#3fd0c6";
				color7 = "#a9bdb8";

				# Colors - Bright
				color8  = "#3a4644";
				color9  = "#ff5e74";
				color10 = "#5fd6a0";
				color11 = "#ffd76a";
				color12 = "#3fd0c6";
				color13 = "#f06ea0";
				color14 = "#6fe0d6";
				color15 = "#d3e4df";
			};

			keybindings = {
				# Navigazione tra pannelli/split affiancati
				"ctrl+left" = "neighboring_window left";
				"ctrl+right" = "neighboring_window right";

				# Creazione Split
				"ctrl+shift+enter" = "new_window";
    			"ctrl+shift+l" = "next_layout";

				# Gestione Tab stile Browser
				"ctrl+t" = "new_tab";
				"ctrl+w" = "close_tab";
				"ctrl+tab" = "next_tab";
				"ctrl+shift+tab" = "previous_tab";

				# Navigazione Tab diretta
				"ctrl+1" = "goto_tab 1";
				"ctrl+2" = "goto_tab 2";
				"ctrl+3" = "goto_tab 3";
				"ctrl+4" = "goto_tab 4";
				"ctrl+5" = "goto_tab 5";
				"ctrl+6" = "goto_tab 6";
				"ctrl+7" = "goto_tab 7";
				"ctrl+8" = "goto_tab 8";
				"ctrl+9" = "goto_tab 9";

				# Scorciatoie personalizzate
				"ctrl+;" = "no_op";
				"ctrl+shift+:" = "launch --type=os-window thunar";

				# Ricerca
				"ctrl+shift+f" = "no_op";
				"ctrl+f" = "show_scrollback";

				# Shift+Enter
				"shift+enter" = "send_text all \\x1b[13;2u";
			};
		};

		home.file.".config/Thunar/uca.xml".text	= ''
			<?xml version="1.0" encoding="UTF-8"?>
			<actions>
			<action>
				<icon>utilities-terminal</icon>
				<name>Open Terminal Here</name>
				<submenu></submenu>
				<unique-id>1720621850636761-1</unique-id>
				<command>kitty --working-directory %f</command>
				<description>Open terminal in current directory</description>
				<range></range>
				<patterns>*</patterns>
				<startup-notify/>
				<directories/>
			</action>
			<action>
				<icon>clipboard</icon>
				<name>Copy path</name>
				<submenu></submenu>
				<unique-id>1730572291852956-2</unique-id>
				<command>wl-copy %f ; notify-send &quot;Copied to Clipboard&quot; %f -i clipboard</command>
				<description>Copy current selected file path to clipboard</description>
				<range>*</range>
				<patterns>*</patterns>
				<directories/>
				<audio-files/>
				<image-files/>
				<other-files/>
				<text-files/>
				<video-files/>
			</action>
			<action>
				<icon>link</icon>
				<name>Create symlink</name>
				<submenu></submenu>
				<unique-id>1758831930937907-1</unique-id>
				<command>ln -s %f Link\ to\ %n</command>
				<description>Creates new symbolic link to selected item</description>
				<range>*</range>
				<patterns>*</patterns>
				<directories/>
				<audio-files/>
				<image-files/>
				<other-files/>
				<text-files/>
				<video-files/>
			</action>
			<action>
				<icon>vscode</icon>
				<name>Open Folder with VSCode</name>
				<submenu></submenu>
				<unique-id>1783766142256-2</unique-id>
				<command>env LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib code %f</command>
				<description>Open this folder as a workspace in VSCode</description>
				<range></range>
				<patterns>*</patterns>
				<directories/>
			</action>
			</actions>
		'';
	};
}
