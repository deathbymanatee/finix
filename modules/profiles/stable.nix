{
  config,
  lib,
  pkgs,
  modules,
  ...
}:
let
  cfg = config.profiles.stable;
in
{
  imports = with modules; [
    bash
    fish
    iwd
    dhcpcd
    iwd
    networkmanager
    getty
    nix-daemon
    sysklogd
  ];

  options.profiles.stable = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable the `stable` profile. This profile provides
        a set of user-overrideable defaults that guarantees a 
        working system even through breaking changes in `finix`.

        ::: {.warning}
        Disabling this profile is only recommended for advanced users who 
        have a full understanding of how they want to configure their system and
        who are able to keep up with any breaking changes in `finix`.
        :::
      '';
    };

    deviceManager = lib.mkOption {
      type = lib.types.enum [
        "keventd"
        "mdevd"
        "udev"
        "gardendevd"
      ];
      default = "udev";
      description = ''
        The device manager to use for this system. Available options include:

        - `udev`  — full-featured, matches the rest of the nix ecosystem. broadest compatibility (default)
        - `mdevd` — lighter, from the skarnet/s6 family
        - `keventd` — brand new, udev rule compatible device manager
        - `gardendevd` — brand new, udev rule compatible device manager
      '';
    };

    suBackend = lib.mkOption {
      type = lib.types.enum [
        "sudo"
        "doas"
      ];
      default = "sudo";
      description = ''
        The backend to use for superuser privilege escalation.
      '';
    };

    networking = {
      wired.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to enable wired networking support through `dhcpcd`.
        '';
      };

      wireless.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable wireless networking support through `iwd`.
        '';
      };

      networkmanager.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable NetworkManager. Requires both `udev` and `elogind` to be enabled.
        '';
      };

      firewall.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the `nftables` firewall.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.nixos-rebuild-ng
    ];

    # core programs
    programs.bash.enable = lib.mkDefault true;
    programs.${cfg.suBackend}.enable = lib.mkDefault true;

    # core services
    services.getty.enable = lib.mkDefault true;
    services.sysklogd.enable = lib.mkDefault true;
    services.${cfg.deviceManager}.enable = lib.mkDefault true;
    services.nix-daemon.enable = lib.mkDefault true;
    services.nix-daemon.settings = {
      trusted-users = lib.mkIf config.programs.sudo.enable [
        "root"
        "@wheel"
      ];
    };

    # networking
    services.dhcpcd.enable = !cfg.networking.networkmanager.enable && cfg.networking.wired.enable; # dhcpcd and network will conflict if both are enabled
    services.networkmanager.enable = cfg.networking.networkmanager.enable;
    services.nftables.enable = cfg.networking.firewall.enable;
    services.iwd.enable = cfg.networking.wireless.enable;
  };
}
