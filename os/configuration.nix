# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  self,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

#TODO: add build script that cds in $XDG_DATA_HOME/nvim/lazy-telescope-fzf-native.nvim and runs `make`

let
  userHome = config.users.users.v.home;

  modularHome = "${userHome}/.modular";

  systemdCat = "${pkgs.systemd}/bin/systemd-cat";
  sway = "${config.programs.sway.package}/bin/sway";
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services = {
    xserver = {
      enable = false;
      autorun = false; # no clue if it does anything if `enable = false`, but might as well keep it
      xkb = {
        extraLayouts.semimak = {
          description = "Semimak for both keyboard standards";
          languages = [ "eng" ];
          symbolsFile = /usr/share/X11/xkb/symbols/semimak;
        };
        layout = "semimak";
        variant = "iso";
        options = "grp:win_space_toggle";
      };
    };

    keyd.enable = true;
    #xwayland.enable = true;

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    printing.enable = true;
    libinput.enable = true;
    openssh.enable = true;
    blueman.enable = true;
  };
  programs = {
    firefox.enable = true;
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
    sway.xwayland.enable = true;
    fish.enable = true;

    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 7d";
      };
    };
  };
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;

  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
    };
    timeout = 0; # spam `Space` or `Shift` to bring the menu up when needed
    efi.canTouchEfiVariables = true;

    #grub.useOsProber = true; # need to find alternative for systemd-boot
  };

  # Set your time zone.
  time.timeZone = "UTC";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  hardware = {
    pulseaudio.enable = false;
    bluetooth.enable = true;
    bluetooth.powerOnBoot = false;
  };

  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        %wheel ALL=(ALL) NOPASSWD: ALL
      '';
    };
    rtkit.enable = true;
    polkit.enable = true;
  };

  users.users.v = {
    isNormalUser = true;
    description = "v";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "keyd"
      "audio"
      "video"
    ];
  };

  services.getty.autologinUser = "v";

  systemd = {
    user.services = {
      mpris-proxy = {
        description = "Mpris proxy";
        after = [
          "network.target"
          "sound.target"
        ];
        wantedBy = [ "default.target" ];
        serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      };
    };
  };

  fonts = {
    #NB: many of the icons will be overwritten by nerd-fonts. If a character is not rendering properly, use `nerdfix` on the repo, search for correct codepoint in https://www.nerdfonts.com/cheat-sheet
    packages = with pkgs; [
      fira-code
      fira-code-nerdfont
      fira-code-symbols
      agave
      corefonts
      dejavu_fonts
      dina-font
      emojione
      font-awesome
      julia-mono
      font-awesome_4
      font-awesome_5
      texlivePackages.fontawesome5
      texlivePackages.fontawesome
      google-fonts
      ipafont
      jetbrains-mono
      kanji-stroke-order-font
      liberation_ttf
      material-design-icons
      mplus-outline-fonts.githubRelease
      nerdfonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      ocamlPackages.codicons
      powerline-fonts
      profont
      proggyfonts
      source-code-pro
      texlivePackages.arimo
      texlivePackages.dejavu
      ubuntu_font_family
    ];
    fontconfig.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment = {
    # XDG directories and Wayland environment variables setup
    variables = {
      XDG_DATA_HOME = "${userHome}/.local/share";
      XDG_CONFIG_HOME = "${userHome}/.config";
      XDG_CACHE_HOME = "${userHome}/.cache";
      XDG_CURRENT_DESKTOP = "sway";
      GDK_BACKEND = "wayland";
      XDG_BACKEND = "wayland";
      QT_WAYLAND_FORCE_DPI = "physical";
      QT_QPA_PLATFORM = "wayland-egl";
      CLUTTER_BACKEND = "wayland";
      SDL_VIDEODRIVER = "wayland";
      BEMENU_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";

      # Other specific environment variables
      GIT_CONFIG_HOME = "${userHome}/.config/git/config";
      QT_QPA_PLATFORMTHEME = "flatpak";
      GTK_USE_PORTAL = "1";
      GDK_DEBUG = "portals";

      # Nix
      NIXOS_CONFIG = "/etc/nixos";
      # #HACK
      #NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
      #	stdenv.cc.cc
      #	openssl
      #	openssl.dev
      #	# ...
      #];
      LD_DEBUG = "libs";
      #NIX_LD = with pkgs; lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker"; # auto-setup
      #

      # home vars
      MODULAR_HOME = "${modularHome}";
      #PATH = "${pkgs.lib.makeBinPath [ ]}:${userHome}/s/evdev/:${userHome}/.cargo/bin/:${userHome}/go/bin/:/usr/lib/rustup/bin/:${userHome}/.local/bin/:${modularHome}/pkg/packages.modular.com_mojo/bin:${userHome}/.local/share/flatpak:/var/lib/flatpak";
      EDITOR = "nvim";
      WAKETIME = "5:00";
      DAY_SECTION_BORDERS = "2.5:10.5:16";
      PAGER = "less";
      MANPAGER = "less";
      LESSHISTFILE = "-";
      HISTCONTROL = "ignorespace";

      # openssl hurdle
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.wayland-scanner.bin}/bin"; # :${pkgs.openssl}/lib"; # many of my rust scripts require it
      # dbg
      #LD_LIBRARY_PATH = lib.mkDefault (lib.makeLibraryPath [ pkgs.openssl pkgs.pipewire.jack ]);
    };

    binsh = "${pkgs.dash}/bin/dash";

    #naersk
    #(naersk.buildPackage {
    #	src = "${userHome}/s/tg";
    #})
    #inputs.helix.packages."${pkgs.system}".helix
    #TODO!: make structure modular, using [flatten](<https://noogle.dev/f/lib/flatten>)
    systemPackages =
      with pkgs; # basically `use pkgs::*`
      lib.lists.flatten [
        difftastic
        flatpak
        nix-output-monitor
        keyd
        libinput-gestures
        sccache
        fractal # matrix chat protocol adapter
        nh
        haskellPackages.greenclip
        cachix
        lefthook # git hooks
        wayland-scanner
        nerdfix # fixes illegal font codepoints https://discourse.nixos.org/t/nerd-fonts-only-see-half-the-icon-set/27513
        poppler_utils
        manix # grep nixpkgs docs

        # UI/UX Utilities
        [
          adwaita-qt
          bemenu
          blueman
          eww
          grim
          slurp
          mako
          networkmanagerapplet
          rofi
          swappy
        ]

        # System Utilities
        [
          alsa-utils
          dbus
          hwinfo
          dconf
          file
          gsettings-desktop-schemas
          libnotify
          lm_sensors # for `sensors` command
          lsof
          pamixer
          pavucontrol
          pciutils # lspci
          sysstat
          usbutils # lsusb
          which
          wireplumber
          wl-clipboard
          wl-gammactl
          xorg.xkbcomp
          xz
        ]

        # Network Tools
        [
          aria2 # better wget
          dnsutils # `dig` + `nslookup`
          ethtool
          iftop # network monitoring
          iotop # io monitoring
          ipcalc # IPv4/v6 address calculator
          iperf3
          mtr # Network diagnostic tool
          nmap # Network discovery/security auditing
          socat # replacement of openbsd-netcat
        ]

        # Monitoring and Performance
        [
          bottom
          lm_sensors # System sensor monitoring
          ltrace # Library call monitoring
          strace # System call monitoring
        ]

        # Compression and Archiving
        [
          atool
          p7zip
          unzip
          zip
          xz
          zstd
        ]

        # Command Line Enhancements
        [
          dust # `du` in rust
          atuin
          tldr
          cowsay
          cotp
          eza # better `ls`
          fd # better `find`
          bat # better `cat`
          ripgrep # better `grep`
          fzf
          jq
          keyd
          tree
          zoxide
        ]

        # terminals
        [
          starship
          alacritty
          tmux
          tmuxPlugins.resurrect # persist sessions
          tmuxPlugins.open # open files
          tmuxPlugins.copycat # enables regex
        ]

        # Networking Tools
        [
          bluez
          dnsutils
          ipcalc
          iperf3
          mtr
          nmap
          pciutils # lspci
          usbutils # lsusb
          wireplumber
        ]

        # File Utilities
        [
          fd # better `find`
          file
          gnupg
          gnused
          gnutar
          jq
          unzip
          zip
          pandoc
        ]

        # Audio/Video Utilities
        [
          pamixer
          vlc
          pulsemixer
          pavucontrol
          mpv
          obs-studio
          obs-cli
          ffmpeg
        ]

        # System Monitoring and Debugging
        [
          iftop # network monitoring
          iotop # io monitoring
          sysstat
          ltrace
          strace
        ]

        # Web/Network Interaction
        [
          httpie
          google-chrome
          chromium
          firefox
          wget
          aria2
        ]

        # shells
        [
          zsh
          fish
          fishPlugins.bass
          dash
        ]

        # Development Tools
        [
          gh
          git
          glib
          pkg-config # when used in build scripts, must be included in `nativeBuildInputs`. Only _native_ will work.
          openssl
          tokei
          direnv
        ]

        # Coding
        [
          vscode-extensions.github.copilot
          mold
          sccache

          # editors
          [
            neovim
            vim
            vscode
          ]

          # language-specific
          [
            vscode-langservers-extracted # contains json lsp
            marksman # md lsp
            lean4
            perl

            # Js / Ts
            [
              nodejs_22
              deno
            ]

            # typst
            [
              typst
              typst-lsp
              typstyle # formatter
            ]
            # nix
            [
              nil # nix lsp
              niv # nix build dep management
              nix-diff
              statix # Lints and suggestions for the nix programming language
              deadnix # Find and remove unused code in .nix source files

              # formatters
              [
                nixfmt-rfc-style
                nixpkgs-fmt
                alejandra # Nix Code Formatter; not sure how it compares with nixpkgs-fmt
              ]
            ]
            # python
            [
              python3
              python312Packages.pip
              python312Packages.jedi-language-server
              ruff
              ruff-lsp
            ]
            # golang
            [
              go
              gopls
            ]
            # rust
            [
              # cargo, rustcs, etc are brought in by fenix.nix
              rustup
              crate2nix
              cargo-edit
              cargo-hack
              cargo-udeps
              cargo-outdated
              cargo-sort
              cargo-insta
              cargo-mutants
              cargo-update
              #cargo-binstall
              cargo-machete
              cargo-release
              cargo-watch
              cargo-nextest
              cargo-limit # brings `lrun` and other `l$command` aliases for cargo, that suppress warnings if any errors are present.
            ]

            # C/C++
            [
              clang
              clang-tools
              cmake
              gnumake
            ]

            # lua
            [
              lua
              lua-language-server
            ]
          ]

          # Debuggers
          [
            lldb
            pkgs.llvmPackages.bintools
            vscode-extensions.vadimcn.vscode-lldb
          ]
        ]
      ];
  };

  #TODO!: make specific to the host
  networking = {
    firewall.allowedTCPPorts = [
      57621 # for spotify
    ];
    firewall.allowedUDPPorts = [
      5353 # for spotify
    ];

    hostName = "v_laptop";
    networkmanager.enable = true;
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  # replaced by `nh.clean`
  #nix.gc = {
  #  automatic = true;
  #  dates = "weekly";
  #  options = "--delete-older-than 1w";
  #};
  nix.settings.auto-optimise-store = true; # NB: can slow down individual builds; alternative: schedule optimise passes: https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  system.stateVersion = "24.05"; # NB: changing requires migration
}
