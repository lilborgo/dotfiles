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
		kernelPackages	= pkgs.linuxPackages_latest;
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
			allowedTCPPorts	= [];
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
				"plugdev" "video" "wheel"
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
				cat		= "bat";
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
				alsa-lib atk bash cairo dbus expat fontconfig
				freetype gcc gcc.cc.lib glib libgbm libGL libice
				libnotify libsm libxcb libxcomposite libxdamage
				libxext libxfixes libxkbcommon libxrandr libxrender
				lttng-ust nspr nss pango polkit stdenv.cc.cc.lib
				wayland libx11 libxcursor libxi gnupg libGL
				libxrandr zlib gtk3 fribidi harfbuzz libtorch-bin
				cups
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

	# --- Power management ---
	services.upower.enable					= true;

	# --- Desktop utilities ---
	services.flatpak.enable		= true;
	services.gnome.gnome-keyring.enable	= true;
	services.gvfs.enable		= true;
	services.playerctld.enable	= true;
	services.tumbler.enable		= true;
	services.udisks2.enable		= true;

	# --- Virtualisation guests ---
	services.qemuGuest.enable			= true;
	services.spice-vdagentd.enable	= true;

	# --- Misc ---
	systemd.services.NetworkManager-wait-online.enable	= false;
	systemd.tmpfiles.rules	= [
		"L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
	];


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
		waydroid	= {
			enable	= true;
			package	= pkgs.waydroid-nftables;
		};
	};


	#	============================================================
	# XDG PORTALS
	#	============================================================

	xdg.portal	= {
		enable				= true;
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
		LD_LIBRARY_PATH = "$NIX_LD_LIBRARY_PATH";
	};

	environment.systemPackages	= with pkgs; [
		# --- Terminal & shell utilities ---
		bash bat btop busybox eza fd file fzf htop ncdu
		ripgrep smem tree wget alacritty exfat srecord
		poppler-utils glib sshpass dig
		curl duf hexyl lsof tealdeer tmux rsync
		watch parallel mosh

		# --- Build tools & compilers ---
		cargo clang clang-tools cmake gcc gcc.cc.lib glibc
		gnumake rustc binutils

		# --- Development ---
		gh git nano nom gnome-text-editor micro
		(python3.withPackages (ps: with ps; [
			paho-mqtt pypdf torch torchvision matplotlib 
			west tkinter pyserial pyelftools pyyaml pykwalify 
			packaging patool psutil pylink-square requests
			semver tqdm reuse anytree intelhex colorama
			cryptography cbor pyocd jsonschema canopen
		]))
		unstable.vscode unstable.claude-code probe-rs-tools
		gnirehtet tio jetbrains.idea libtorch-bin dbeaver-bin
		nodejs dtc wireshark pyocd
		jq yq-go delta lazygit sqlite hyperfine tokei
		gdb strace ltrace openssl

		# --- Networking & debugging ---
		tcpdump socat netcat pciutils usbutils

		# --- Nix tools ---
		fastfetch nh nixfmt

		# --- Hyprland & desktop shell ---
		hyprland hypridle hyprshot hyprsunset
		lxsession rofi hyprpaper waybar
	
		# --- GUI applications ---
		duplicati kdePackages.okular file-roller filezilla freefilesync
		gparted impression libqalculate libreoffice-qt localsend
		loupe pavucontrol speedcrunch styluslabs-write-bin
		tor-browser vlc foliate papirus-folders

		# --- Browser ---
		firefox

		# --- Wayland & clipboard ---
		cliphist wev wl-clipboard

		# --- Networking ---
		iproute2 networkmanager networkmanagerapplet nmap wireguard-tools zenmap postman

		# --- Bluetooth ---
		blueman bluez upower

		# --- Hardware & system ---
		brightnessctl libinput libnotify libwacom procps
		smartmontools vulkan-tools

		# --- Theming ---
		adwaita-qt adwaita-qt6 gtk2 gtk3 gtk4

		# --- Virtualisation ---
		spice spice-gtk usbredir virt-manager virt-viewer virtiofsd

		# --- Wine & gaming ---
		steam-run wine wine64

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
			options		= "--delete-older-than 30d";
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
			nixwiki	= {
				name				= "Nixos Wiki";
				exec				= "xdg-open https://search.nixos.org/";
				icon				= "nix-snowflake";
				terminal		= false;
				categories	= [ "Utility" ];
			};
			nmtui	= {
				name				= "nmtui";
				exec				= "nmtui";
				terminal		= true;
				categories	= [ "Network" ];
			};
			spotify	= {
				name				= "Spotify";
				exec				= "xdg-open https://open.spotify.com/";
				icon				= "spotify";
				terminal		= false;
				categories	= [ "Music" ];
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
				"inode/directory"										= "thunar.desktop";

				# PDF
				"application/pdf"										= "org.kde.okular.desktop";
				"application/x-bzpdf"								= "org.kde.okular.desktop";
				"application/x-gzpdf"								= "org.kde.okular.desktop";
				"application/x-pdf"									= "org.kde.okular.desktop";

				# E-books
				"application/epub+zip"								= "com.github.johnfactotum.Foliate.desktop";

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
				"application/javascript"							= "org.gnome.TextEditor.desktop";
				"application/json"										= "org.gnome.TextEditor.desktop";
				"application/toml"										= "org.gnome.TextEditor.desktop";
				"application/typescript"							= "org.gnome.TextEditor.desktop";
				"application/x-desktop"							= "org.gnome.TextEditor.desktop";
				"application/x-sh"										= "org.gnome.TextEditor.desktop";
				"application/x-shellscript"					= "org.gnome.TextEditor.desktop";
				"application/x-yaml"									= "org.gnome.TextEditor.desktop";
				"application/xml"										= "org.gnome.TextEditor.desktop";
				"text/css"														= "org.gnome.TextEditor.desktop";
				"text/csv"														= "org.gnome.TextEditor.desktop";
				"text/markdown"											= "org.gnome.TextEditor.desktop";
				"text/plain"													= "org.gnome.TextEditor.desktop";
				"text/x-asm"													= "org.gnome.TextEditor.desktop";
				"text/x-c"														= "org.gnome.TextEditor.desktop";
				"text/x-c++hdr"											= "org.gnome.TextEditor.desktop";
				"text/x-c++src"											= "org.gnome.TextEditor.desktop";
				"text/x-chdr"												= "org.gnome.TextEditor.desktop";
				"text/x-csrc"												= "org.gnome.TextEditor.desktop";
				"text/x-diff"												= "org.gnome.TextEditor.desktop";
				"text/x-dockerfile"									= "org.gnome.TextEditor.desktop";
				"text/x-go"													= "org.gnome.TextEditor.desktop";
				"text/x-java-source"									= "org.gnome.TextEditor.desktop";
				"text/x-javascript"									= "org.gnome.TextEditor.desktop";
				"text/x-log"													= "org.gnome.TextEditor.desktop";
				"text/x-lua"													= "org.gnome.TextEditor.desktop";
				"text/x-makefile"										= "org.gnome.TextEditor.desktop";
				"text/x-nix"													= "org.gnome.TextEditor.desktop";
				"text/x-patch"												= "org.gnome.TextEditor.desktop";
				"text/x-perl"												= "org.gnome.TextEditor.desktop";
				"text/x-python"											= "org.gnome.TextEditor.desktop";
				"text/x-readme"											= "org.gnome.TextEditor.desktop";
				"text/x-ruby"												= "org.gnome.TextEditor.desktop";
				"text/x-rust"												= "org.gnome.TextEditor.desktop";
				"text/x-script"											= "org.gnome.TextEditor.desktop";
				"text/x-sh"													= "org.gnome.TextEditor.desktop";
				"text/x-sql"													= "org.gnome.TextEditor.desktop";
				"text/x-toml"												= "org.gnome.TextEditor.desktop";
				"text/x-typescript"									= "org.gnome.TextEditor.desktop";
				"text/xml"														= "org.gnome.TextEditor.desktop";

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

		programs.alacritty = {
			enable = true;

			settings = {
				window = {
					dynamic_title = false;
					padding = {
						x = 10;
						y = 10;
					};
				};

				cursor = {
					style = {
						shape = "Underline";
						blinking = "On";
					};
				};

				selection = {
					save_to_clipboard = true;
				};

				keyboard.bindings = [
					{
						key = ";";
						mods = "Control";
						action = "CreateNewWindow";
					}
					{
						key = ":";
						mods = "Control|Shift";
						command = "thunar";
					}
					{
						key = "ArrowUp";
						mods = "Control";
						action = "ScrollLineUp";
					}
					{
						key = "ArrowDown";
						mods = "Control";
						action = "ScrollLineDown";
					}
					{
						key = "F";
						mods = "Control|Shift";
						action = "None";
					}
					{
						key = "F";
						mods = "Control";
						action = "SearchForward";
					}
					{
						key = "F";
						mods = "Control";
						mode = "~Search";
						action = "SearchForward";
					}
					{
						key = "F";
						mods = "Control";
						mode = "Search";
						action = "SearchCancel";
					}
				];

				colors = {
					primary = {
						background = "#0c0f10";
						foreground = "#d3e4df";
					};

					cursor = {
						cursor = "#22c9c0";
					};

					selection = {
						text = "CellForeground";
						background = "#2a3534";
					};

					normal = {
						black = "#1b2122";
						red = "#ec3f5d";
						green = "#46c08a";
						yellow = "#f3c44b";
						blue = "#22c9c0";
						magenta = "#e0588f";
						cyan = "#3fd0c6";
						white = "#a9bdb8";
					};

					bright = {
						black = "#3a4644";
						red = "#ff5e74";
						green = "#5fd6a0";
						yellow = "#ffd76a";
						blue = "#3fd0c6";
						magenta = "#f06ea0";
						cyan = "#6fe0d6";
						white = "#d3e4df";
					};
				};
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
				<command>alacritty --working-directory %f</command>
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
			</actions>
		'';
	};
}
