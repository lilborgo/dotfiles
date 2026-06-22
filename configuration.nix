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
	};

	environment.systemPackages	= with pkgs; [
		# --- Terminal & shell utilities ---
		bash bat btop busybox eza fd file fzf htop ncdu
		ripgrep smem tree wget alacritty exfat srecord
		poppler-utils

		# --- Build tools & compilers ---
		cargo clang clang-tools cmake gcc gcc.cc.lib glibc
		gnumake rustc

		# --- Development ---
		gh git micro nano nom
		(python3.withPackages (ps: with ps; [
			tkinter pyserial paho-mqtt pypdf torch 
			torchvision matplotlib
		]))
		unstable.vscode unstable.claude-code probe-rs-tools
		gnirehtet screen jetbrains.idea libtorch-bin

		# --- Nix tools ---
		fastfetch nh nixfmt

		# --- Hyprland & desktop shell ---
		hyprland hypridle hyprshot hyprsunset
		lxsession rofi swaynotificationcenter swaybg waybar
	
		# --- GUI applications ---
		duplicati kdePackages.okular file-roller filezilla freefilesync
		gparted impression libqalculate libreoffice-qt localsend
		loupe pavucontrol speedcrunch styluslabs-write-bin
		tor-browser vlc foliate

		# --- Browser ---
		firefox

		# --- Wayland & clipboard ---
		cliphist wev wl-clipboard

		# --- Networking ---
		iproute2 networkmanager networkmanagerapplet nmap wireguard-tools

		# --- Bluetooth ---
		blueman bluez upower

		# --- Hardware & system ---
		brightnessctl libinput libnotify libwacom procps
		smartmontools vulkan-tools

		# --- Theming ---
		adwaita-qt gtk2 gtk3 gtk4 tokyonight-gtk-theme candy-icons

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


		# --- Theming ---
		home.pointerCursor	= {
			gtk.enable				= true;
			hyprcursor.enable	= true;
			name							= "Adwaita";
			package						= pkgs.adwaita-icon-theme;
			size							= 24;
		};

		gtk	= {
			enable						= true;
			cursorTheme.name	= "Adwaita";
			iconTheme	= {
				name		= "candy-icons";
				package	= pkgs.candy-icons;
			};
			theme	= {
				name		= "Tokyonight-Dark";
				package	= pkgs.tokyonight-gtk-theme;
			};
			gtk4.theme	= {
				name		= "Tokyonight-Dark";
				package	= pkgs.tokyonight-gtk-theme;
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
				exec				= "alacritty -e micro %F";
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
				"application/javascript"							= "micro.desktop";
				"application/json"										= "micro.desktop";
				"application/toml"										= "micro.desktop";
				"application/typescript"							= "micro.desktop";
				"application/x-desktop"							= "micro.desktop";
				"application/x-sh"										= "micro.desktop";
				"application/x-shellscript"					= "micro.desktop";
				"application/x-yaml"									= "micro.desktop";
				"application/xml"										= "micro.desktop";
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
					Service	= { ExecStart	= cmd; Restart	= "always"; } // extra;
					Install	= { WantedBy	= [ "hyprland-session.target" ]; };
				};
			in {
				hyprsunset	= graphicalService "Hyprsunset blue light filter" "${pkgs.hyprsunset}/bin/hyprsunset"						{ RestartSec	= 5; };
				waybar			= graphicalService "Waybar panel"								 "${pkgs.waybar}/bin/waybar"										{ RestartSec	= 1; };
				lxpolkit		= graphicalService "lxpolkit"										 "${pkgs.lxsession}/bin/lxpolkit"							 { RestartSec	= 1; };
				swaync			= graphicalService "Sway Notification Center"		 "${pkgs.swaynotificationcenter}/bin/swaync"		{ RestartSec	= 1; };
				hypridle		= graphicalService "Hyprland idle"		 "${pkgs.hypridle}/bin/hypridle"		{ RestartSec	= 1; };
			};

		# --- Dotfiles ---
		home.file.".config/alacritty/alacritty.toml".text	= ''
			[window]
			dynamic_title	= false
			padding.x	= 10
			padding.y	= 10

			[cursor]
			style.shape		= "Underline"
			style.blinking	= "On"

			[selection]
			save_to_clipboard	= true

			[keyboard]
			bindings	= [
				{ key	= ";",			 mods	= "Control",				 action	= "CreateNewWindow" },
				{ key	= ":",			 mods	= "Control | Shift",	command	= "thunar" },
				{ key	= "ArrowUp", mods	= "Control",					action	= "ScrollLineUp" },
				{ key	= "ArrowDown", mods	= "Control",				action	= "ScrollLineDown" },
				{ key	= "F", mods	= "Control | Shift",				action	= "None" },
				{ key	= "F", mods	= "Control",								action	= "SearchForward" },
				{ key	= "F", mods	= "Control", mode	= "~Search", action	= "SearchForward" },
				{ key	= "F", mods	= "Control", mode	= "Search",	action	= "SearchCancel" }
			]

			[colors.primary]
			background	= "#0c0f10"
			foreground	= "#d3e4df"

			[colors.cursor]
			cursor	= "#22c9c0"

			[colors.selection]
			text				= "CellForeground"
			background	= "#2a3534"

			[colors.normal]
			black		= "#1b2122"
			red			= "#ec3f5d"
			green		= "#46c08a"
			yellow	= "#f3c44b"
			blue		= "#22c9c0"
			magenta	= "#e0588f"
			cyan		= "#3fd0c6"
			white		= "#a9bdb8"

			[colors.bright]
			black		= "#3a4644"
			red			= "#ff5e74"
			green		= "#5fd6a0"
			yellow	= "#ffd76a"
			blue		= "#3fd0c6"
			magenta	= "#f06ea0"
			cyan		= "#6fe0d6"
			white		= "#d3e4df"
		'';

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
