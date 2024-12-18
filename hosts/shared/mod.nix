{
  self,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
	#XXX: currently not sourced
	programs = {
    neovim = {
      defaultEditor = true; # sets $EDITOR
      #? Can I get a nano alias?
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    direnv.enable = true;
		eza.enable = true;
	};
  home.sessionPath = [
    "${pkgs.lib.makeBinPath [ ]}"
    "${config.home.homeDirectory}/s/evdev/"
    "${config.home.homeDirectory}/.cargo/bin/"
    "${config.home.homeDirectory}/go/bin/"
    "/usr/lib/rustup/bin/"
    "${config.home.homeDirectory}/.local/bin/"
    "${config.home.homeDirectory}/pkg/packages.modular.com_mojo/bin"
    "${config.home.homeDirectory}/.local/share/flatpak"
    "/usr/bin"
    "/var/lib/flatpak"
  ];

  dconf = {
		enable = true;
		settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
