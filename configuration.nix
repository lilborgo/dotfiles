{ config, pkgs, ... }:

let
  home-manager-src = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";

  plasma-manager-src = builtins.fetchTarball "https://github.com/nix-community/plasma-manager/archive/trunk.tar.gz";
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
  services.desktopManager.plasma6.enable = true;
  services.printing.enable = true;
  services.libinput.enable = true;
  services.pulseaudio.enable = false;
  services.spice-vdagentd.enable = true;
  services.flatpak.enable = true;
  services.xserver.wacom.enable = true;
  services.blueman.enable = true;
  services.playerctld.enable = true;
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
  programs.kdeconnect.enable = true;
  programs.virt-manager.enable = true;
  programs.steam.enable = true;
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
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

  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kdePackages.ark
    kdePackages.isoimagewriter
    kdePackages.okular
    kdePackages.kdenlive
    kdePackages.gwenview
    kdePackages.elisa
    kdePackages.kcolorchooser
    kdePackages.kate
    kdePackages.filelight
    kdePackages.kdeconnect-kde
    kdePackages.qtstyleplugin-kvantum
    kdePackages.partitionmanager
    kdePackages.sweeper
    kdePackages.spectacle
    kdePackages.krdc
    kdePackages.ktorrent
    kdePackages.skanpage
    kdePackages.kjournald
    kdePackages.kamoso
    kdePackages.krfb
    kdePackages.kget
    kdePackages.kalgebra
    kdePackages.knights
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers
    kdePackages.powerdevil
    kdePackages.qttools

    waybar
    pavucontrol
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
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
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-vcs-plugin
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
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
    candy-icons
    sweet
    sweet-nova
  ];

  home-manager.sharedModules = [
    (import "${plasma-manager-src}/modules")
  ];

  home-manager.users.fede= { pkgs, ...}:
  {
    home.stateVersion = "23.11";

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };


    programs.plasma= {
      enable = true;

      hotkeys.commands."launch-librewolf" = {
        name = "Launch librewolf";
        key = "Meta+F";
        command = "librewolf";
      };

      configFile = {
        kwinrc.Desktops = {
          Number = {
            value = 8;
            immutable = true;
          };
          Rows = {
            value = 2;
            immutable = true;
            };
        };

        ksmserverrc.General = {
          loginMode = {
            value = "emptySession";
            immutable = true;
          };
        };
      };
    };
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

