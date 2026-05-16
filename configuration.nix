{ config, pkgs, ... }:

let
  home-manager-src = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
in
{
  imports =
  [
    /etc/nixos/hardware-configuration.nix
    (import "${home-manager-src}/nixos")
    /etc/nixos/custom.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  systemd.services.NetworkManager-wait-online.enable = false;

  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "gtk2";
  };

  services.xserver.enable = true;
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];
  services.displayManager.ly.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    gutenprintBin
  ];
  services.libinput.enable = true;
  services.pulseaudio.enable = false;
  services.spice-vdagentd.enable = true;
  services.flatpak.enable = true;
  services.xserver.wacom.enable = true;
  services.blueman.enable = true;
  services.playerctld.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;
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
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  console.keyMap = "it2";
  security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.gamemode.enable = true;
  programs.virt-manager.enable = true;
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.xfconf.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  programs = {
    zsh = {
      shellAliases = {
        switch = "nh os switch -f '<nixpkgs/nixos>' -- -I nixos-config=/etc/nixos/configuration.nix";
        mem = "sudo smem -tk -c \"pid user name uss pss rss\"";
      };

      enable = true;
      autosuggestions.enable = true;
      autosuggestions.strategy = ["history" "completion"];
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
    libglibutil
    glib
    nspr
    polkit
    nss
    dbus
    atk
    cairo
    gtk3
    pango
    expat
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libgbm
    libxcb
    alsa-lib
    bash
  ];

  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

  users.users.fede = {
    isNormalUser = true;
    description = "fede";
    extraGroups = [
      "lp"
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

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_SCALE_FACTOR = "1.5";
  };

  environment.systemPackages = with pkgs; [
    waybar
    gparted
    smem
    hyprshot
    pavucontrol
    evince
    kdePackages.gwenview
    kdePackages.ark
    micro
    qdirstat
    libreoffice-qt
    hyprland
    rofi
    swaynotificationcenter
    networkmanager
    networkmanagerapplet
    bluez
    blueman
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
    hypridle
    libnotify
    htop
    brightnessctl
    libinput
    libwacom
    busybox
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
    styluslabs-write-bin
    vlc
    fastfetch
    python3
    nh
    nom
    rustc
    cargo
    gcc
    gcc.cc.lib
    gnumake
    glibc
    cmake
    gh
    nano
    git
    tree
    wget
    btop
    libqalculate
    speedcrunch
    clang
    clang-tools
    zip
    unzip
    p7zip
    gnutar
    gzip
    bzip2
    xz
    zstd
    cups-filters
    lxsession
    file
    steam-run
    impression
  ];

  home-manager.users.fede= { pkgs, ...}:
  {
    home.stateVersion = "23.11";

    systemd.user.services.waybar = {
      Unit = {
        Description = "Waybar panel";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        Restart = "always";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.lxpolkit = {
      Unit = {
        Description = "lxpolkit";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.lxsession}/bin/lxpolkit";
        Restart = "always";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.swaync = {
      Unit = {
        Description = "Sway Notification Center";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
        Restart = "always";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    home.pointerCursor = {
      gtk.enable = true;
      hyprcursor.enable = true;
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
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
        name = "Nordic";
        package = pkgs.nordic;
      };
      cursorTheme = {
        name = "Adwaita";
      };
    };

    xdg.desktopEntries.micro = {
      name = "Micro";
      exec = "alacritty -e micro %F";
      terminal = false;
      mimeType = [
        "text/plain"
      ];
      categories = [ "Utility" "TextEditor" ];
    };

    xdg.desktopEntries.nmtui = {
      name = "nmtui";
      exec = "alacritty -e nmtui";
      terminal = false;
      categories = [ "Network" ];
    };

    xdg.desktopEntries.nixwiki = {
      name = "Nixos Wiki";
      exec = "xdg-open https://search.nixos.org/";
      terminal = false;
      categories = [ "Utility"];
      icon = "nix-snowflake";
    };

    xdg.desktopEntries.spotify = {
      name = "Spotify";
      exec = "xdg-open https://open.spotify.com/";
      terminal = false;
      categories = [ "Music"];
      icon = "spotify";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # Browser
        "text/html"                          = "librewolf.desktop";
        "x-scheme-handler/http"              = "librewolf.desktop";
        "x-scheme-handler/https"             = "librewolf.desktop";
        "x-scheme-handler/ftp"               = "librewolf.desktop";
        "application/xhtml+xml"              = "librewolf.desktop";
        "application/x-extension-htm"        = "librewolf.desktop";
        "application/x-extension-html"       = "librewolf.desktop";
        "application/x-extension-xhtml"      = "librewolf.desktop";

        # File manager
        "inode/directory"                    = "thunar.desktop";

        # PDF
        "application/pdf"                    = "org.gnome.Evince.desktop";
        "application/x-pdf"                  = "org.gnome.Evince.desktop";
        "application/x-bzpdf"                = "org.gnome.Evince.desktop";
        "application/x-gzpdf"                = "org.gnome.Evince.desktop";

        # Images
        "image/png"                          = "org.kde.gwenview.desktop";
        "image/jpeg"                         = "org.kde.gwenview.desktop";
        "image/jpg"                          = "org.kde.gwenview.desktop";
        "image/gif"                          = "org.kde.gwenview.desktop";
        "image/webp"                         = "org.kde.gwenview.desktop";
        "image/tiff"                         = "org.kde.gwenview.desktop";
        "image/bmp"                          = "org.kde.gwenview.desktop";
        "image/svg+xml"                      = "org.kde.gwenview.desktop";
        "image/x-portable-pixmap"            = "org.kde.gwenview.desktop";
        "image/avif"                         = "org.kde.gwenview.desktop";
        "image/heic"                         = "org.kde.gwenview.desktop";

        # Video
        "video/mp4"                          = "vlc.desktop";
        "video/x-matroska"                   = "vlc.desktop";
        "video/webm"                         = "vlc.desktop";
        "video/avi"                          = "vlc.desktop";
        "video/x-msvideo"                    = "vlc.desktop";
        "video/quicktime"                    = "vlc.desktop";
        "video/x-flv"                        = "vlc.desktop";
        "video/mpeg"                         = "vlc.desktop";
        "video/ogg"                          = "vlc.desktop";
        "video/3gpp"                         = "vlc.desktop";
        "video/x-ms-wmv"                     = "vlc.desktop";
        # Audio
        "audio/mpeg"                         = "vlc.desktop";
        "audio/ogg"                          = "vlc.desktop";
        "audio/flac"                         = "vlc.desktop";
        "audio/wav"                          = "vlc.desktop";
        "audio/x-wav"                        = "vlc.desktop";
        "audio/aac"                          = "vlc.desktop";
        "audio/mp4"                          = "vlc.desktop";
        "audio/x-m4a"                        = "vlc.desktop";
        "audio/opus"                         = "vlc.desktop";
        "audio/webm"                         = "vlc.desktop";

        # Text editor — using gedit, lightweight and clean
        "text/plain"                         = "micro.desktop";
        "text/x-readme"                      = "micro.desktop";
        "text/x-log"                         = "micro.desktop";
        "text/x-makefile"                    = "micro.desktop";
        "text/x-script"                      = "micro.desktop";
        "application/x-shellscript"          = "micro.desktop";
        "text/x-python"                      = "micro.desktop";
        "text/x-csrc"                        = "micro.desktop";
        "text/x-chdr"                        = "micro.desktop";
        "text/xml"                           = "micro.desktop";
        "text/css"                           = "micro.desktop";
        "application/json"                   = "micro.desktop";
        "application/x-yaml"                 = "micro.desktop";

        # Archives
        "application/zip"                    = "org.kde.ark.desktop";
        "application/x-tar"                  = "org.kde.ark.desktop";
        "application/x-compressed-tar"       = "org.kde.ark.desktop";
        "application/x-bzip2-compressed-tar" = "org.kde.ark.desktop";
        "application/x-xz-compressed-tar"    = "org.kde.ark.desktop";
        "application/x-7z-compressed"        = "org.kde.ark.desktop";
        "application/x-rar"                  = "org.kde.ark.desktop";
        "application/x-rar-compressed"       = "org.kde.ark.desktop";

        # Torrents
        "application/x-bittorrent"           = "vlc.desktop";

        # Email
        "x-scheme-handler/mailto"            = "librewolf.desktop";
      };
    };


    home.file.".config/alacritty/alacritty.toml".text = ''
      [window]
      dynamic_title = false
      padding.x = 10
      padding.y = 10

      [cursor]
      # style.shape = "Beam"
      style.shape = "Underline"
      style.blinking = "On"

      [selection]
      save_to_clipboard = true

      [keyboard]
      bindings = [
        { key = ";", mods = "Control", action = "CreateNewWindow" },
        { key = ":", mods = "Control | Shift", command = "thunar" },
        { key = "ArrowUp", mods = "Control", action = "ScrollLineUp" },
        { key = "ArrowDown", mods = "Control", action = "ScrollLineDown" },

        { key = "F", mods = "Control | Shift", action = "None" },
        { key = "F", mods = "Control", action = "SearchForward" }, 
        { key = "F", mods = "Control", mode = "~Search", action = "SearchForward" },  
        { key = "F", mods = "Control", mode = "Search", action = "SearchCancel" }
      ]

      [colors.primary]
      background = "#08080b"
      foreground = "#787c99"

      [colors.cursor]
      cursor = "#787c99"

      [colors.selection]
      text = "CellForeground"
      background = "#515c7e"

      [colors.normal]
      black = "#363b54"
      red = "#f7768e"
      green = "#41a6b5"
      yellow = "#e0af68"
      blue = "#7aa2f7"
      magenta = "#bb9af7"
      cyan = "#7dcfff"
      white = "#787c99"

      [colors.bright]
      black = "#363b54"
      red = "#f7768e"
      green = "#41a6b5"
      yellow = "#e0af68"
      blue = "#7aa2f7"
      magenta = "#bb9af7"
      cyan = "#7dcfff"
      white = "#acb0d0"
    ''; 

    home.file.".config/Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Open Terminal Here</name>
        <submenu></submenu>
        <unique-id>1720621850636761-1</unique-id>
        <command>alacritty --working-directory %f</command>
        <description>Example for a custom action</description>
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
        <description>Copy current selected file&apos;s directory (with name) to the clipboard</description>
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
    '';
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

