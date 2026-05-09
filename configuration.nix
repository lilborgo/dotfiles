{ config, pkgs, ... }:

let
  home-manager-src = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
in
{
  imports =
  [
    /etc/nixos/hardware-configuration.nix
    (import "${home-manager-src}/nixos")
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = ["kvm-amd" "kvm"];

  qt.style = "kvantum";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.bluetooth.enable = true;
  hardware.enableAllFirmware = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];
  };

  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "it_IT.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  #amdgpu modesetting nvidia
  systemd.services.NetworkManager-wait-online.enable = false;
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.enable = true;
  services.displayManager.ly.enable = true;
  services.printing.enable = true;
  services.libinput.enable = true;
  services.pulseaudio.enable = false;
  services.spice-vdagentd.enable = true;
  services.flatpak.enable = true;
  services.xserver.wacom.enable = true;
  services.blueman.enable = true;
  services.playerctld.enable = true;
  services.gvfs.enable = true;
  services.xserver.xkb = {
    layout = "it";
    variant = "";
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  console.keyMap = "it2";
  security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = false;
  users.defaultUserShell = pkgs.zsh;

  programs.gamemode.enable = true;
  programs.virt-manager.enable = true;
  programs.steam.enable = true;
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.xfconf.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin # Requires an Archive manager like file-roller, ark, etc
      thunar-volman
    ];
  };
  programs = {
    zsh = {
      shellAliases = {
        switch = "nh os switch -f '<nixpkgs/nixos>' -- -I nixos-config=/etc/nixos/configuration.nix";
      };

      enable = true;
      autosuggestions.enable = true;
      zsh-autoenv.enable = true;
      syntaxHighlighting.enable = true;

      ohMyZsh = {
        enable = true;
        theme = "bira";
        plugins = [
          "git"
        ];
      };
    };
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    libGL
    wayland
    libxkbcommon
  ];


  users.users.fede = {
    isNormalUser = true;
    description = "fede";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "libvirtd"
      "kvm"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package =  pkgs.waydroid-nftables;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
    noto-fonts
    cascadia-code
    nerd-fonts.caskaydia-mono
  ];

  environment.systemPackages = with pkgs; [
    waybar
    pavucontrol
    zathura
    imv
    hyprland
    rofi
    swaynotificationcenter
    networkmanager
    networkmanagerapplet
    bluez
    blueman
    kitty
    gnome-power-manager
    upower
    iproute2
    procps
    bash
    cliphist
    wl-clipboard
    wev
    alacritty
    papirus-icon-theme
    gtk2
    gtk3
    gtk4
    swaybg
    flameshot
    hypridle
    libnotify
    htop
    brightnessctl
    kdePackages.qtstyleplugin-kvantum
    kdePackages.ark
    libinput
    libwacom
    busybox
    vscode
    android-tools
    scrcpy
    librewolf
    duplicati
    filezilla
    smartmontools
    localsend
    wine
    wine64
    freefilesync
    tor-browser
    nmap
    gzdoom
    styluslabs-write-bin
    vlc
    neofetch
    prismlauncher
    python3
    gnuchess
    nh
    nom
    rustc
    cargo
    gcc
    gcc.cc.lib
    gnumake
    glibc
    cmake
    ungoogled-chromium
    discord
    spotify
    anydesk
    gvfs
    gh
    git
    nano
    git
    tree
    wget
    btop
    libqalculate
    speedcrunch
  ];

  home-manager.users.fede= { pkgs, ...}:
  {
    home.stateVersion = "23.11";

    home.pointerCursor = {
      gtk.enable = true;
      hyprcursor.enable = true;
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };

    programs.git = {
      enable = true;

      settings.user = {
        email = "federico.borgo.03@gmail.com";
        name = "Federico Borgo";
      };
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
      cursorTheme = {
        name = "Adwaita";
      };
    };

    #xdg.mimeApps = {
    #  enable = true;
    #  defaultApplications = {
    #    # Browser
    #    "text/html"                          = "librewolf.desktop";
    #    "x-scheme-handler/http"              = "librewolf.desktop";
    #    "x-scheme-handler/https"             = "librewolf.desktop";
    #    "x-scheme-handler/ftp"               = "librewolf.desktop";
    #    "application/xhtml+xml"              = "librewolf.desktop";
    #    "application/x-extension-htm"        = "librewolf.desktop";
    #    "application/x-extension-html"       = "librewolf.desktop";
    #    "application/x-extension-xhtml"      = "librewolf.desktop";
#
    #    # File manager
    #    "inode/directory"                    = "thunar.desktop";
#
    #    # PDF
    #    "application/pdf"                    = "zathura.desktop";
    #    "application/x-pdf"                  = "zathura.desktop";
    #    "application/x-bzpdf"                = "zathura.desktop";
    #    "application/x-gzpdf"                = "zathura.desktop";
#
    #    # Images
    #    "image/png"                          = "imv.desktop";
    #    "image/jpeg"                         = "imv.desktop";
    #    "image/jpg"                          = "imv.desktop";
    #    "image/gif"                          = "imv.desktop";
    #    "image/webp"                         = "imv.desktop";
    #    "image/tiff"                         = "imv.desktop";
    #    "image/bmp"                          = "imv.desktop";
    #    "image/svg+xml"                      = "imv.desktop";
    #    "image/x-portable-pixmap"            = "imv.desktop";
    #    "image/avif"                         = "imv.desktop";
    #    "image/heic"                         = "imv.desktop";
#
    #    # Video
    #    "video/mp4"                          = "vlc.desktop";
    #    "video/x-matroska"                   = "vlc.desktop";
    #    "video/webm"                         = "vlc.desktop";
    #    "video/avi"                          = "vlc.desktop";
    #    "video/x-msvideo"                    = "vlc.desktop";
    #    "video/quicktime"                    = "vlc.desktop";
    #    "video/x-flv"                        = "vlc.desktop";
    #    "video/mpeg"                         = "vlc.desktop";
    #    "video/ogg"                          = "vlc.desktop";
    #    "video/3gpp"                         = "vlc.desktop";
    #    "video/x-ms-wmv"                     = "vlc.desktop";
#
    #    # Audio
    #    "audio/mpeg"                         = "vlc.desktop";
    #    "audio/ogg"                          = "vlc.desktop";
    #    "audio/flac"                         = "vlc.desktop";
    #    "audio/wav"                          = "vlc.desktop";
    #    "audio/x-wav"                        = "vlc.desktop";
    #    "audio/aac"                          = "vlc.desktop";
    #    "audio/mp4"                          = "vlc.desktop";
    #    "audio/x-m4a"                        = "vlc.desktop";
    #    "audio/opus"                         = "vlc.desktop";
    #    "audio/webm"                         = "vlc.desktop";
#
    #    # Text editor — using gedit, lightweight and clean
    #    #"text/plain"                         = "org.gnome.gedit.desktop";
    #    #"text/x-readme"                      = "org.gnome.gedit.desktop";
    #    #"text/x-log"                         = "org.gnome.gedit.desktop";
    #    #"text/x-makefile"                    = "org.gnome.gedit.desktop";
    #    #"text/x-script"                      = "org.gnome.gedit.desktop";
    #    #"application/x-shellscript"          = "org.gnome.gedit.desktop";
    #    #"text/x-python"                      = "org.gnome.gedit.desktop";
    #    #"text/x-csrc"                        = "org.gnome.gedit.desktop";
    #    #"text/x-chdr"                        = "org.gnome.gedit.desktop";
    #    #"text/xml"                           = "org.gnome.gedit.desktop";
    #    #"text/css"                           = "org.gnome.gedit.desktop";
    #    #"application/json"                   = "org.gnome.gedit.desktop";
    #    #"application/x-yaml"                 = "org.gnome.gedit.desktop";
#
    #    # Archives — using thunar with archive plugin (you have it)
    #    "application/zip"                    = "thunar.desktop";
    #    "application/x-tar"                  = "thunar.desktop";
    #    "application/x-compressed-tar"       = "thunar.desktop";
    #    "application/x-bzip2-compressed-tar" = "thunar.desktop";
    #    "application/x-xz-compressed-tar"    = "thunar.desktop";
    #    "application/x-7z-compressed"        = "thunar.desktop";
    #    "application/x-rar"                  = "thunar.desktop";
    #    "application/x-rar-compressed"       = "thunar.desktop";
#
    #    # Torrents
    #    "application/x-bittorrent"           = "vlc.desktop";
#
    #    # Email
    #    "x-scheme-handler/mailto"            = "librewolf.desktop";
    #  };
    #};
  };

  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    randomizedDelaySec = "45min";
    allowReboot = false;
    runGarbageCollection = true;
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    settings = {
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;

      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  system.stateVersion = "25.11";
}

