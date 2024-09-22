{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rofi-themes = {
      url = "github:adi1090x/rofi?subdir=files";
      flake = false;
    };
  };
  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      getModule = putPkgs: import ./config putPkgs;
    in rec {
      nixosModule = getModule (packages: {
        config.system.packages = builtins.attrValues packages;
      });
      hmModule = getModule (packages: {
        config.home.packages = builtins.attrValues packages;
      });
      lib = let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in {
        mkRofiPackages = module:
          (pkgs.lib.evalModules {
            modules = [
              ({config, ...}: {
                config._module.args = {
                  inherit inputs pkgs;
                };
              })
              ({lib, ...}: {
                options.packages = lib.mkOption {
                  type = lib.types.attrsOf lib.types.package;
                  default = [];
                  description = "The output of the packages";
                };
              })
              module
              (getModule (packages: {config.packages = packages;}))
            ];
          })
          .config
          .packages;
        premade = let
          build = name: applet: theme: style:
            (lib.mkRofiPackages (
              {
                pkgs,
                lib,
                ...
              }:
                if applet
                then {
                  config.rofi.applet.${name} = {
                    enable = lib.mkForce true;
                    theme = lib.mkForce theme;
                    style = lib.mkForce style;
                  };
                  config.rofi.package = pkgs.wofi;
                  config.rofi.terminalPackage = pkgs.writeShellScriptBin "foot_wrapper" ''${pkgs.foot}/bin/foot $*'';
                }
                else {
                  config.rofi.${name} = {
                    enable = lib.mkForce true;
                    theme = lib.mkForce theme;
                    style = lib.mkForce style;
                  };
                  config.rofi.package = pkgs.wofi;
                  config.rofi.terminalPackage = pkgs.writeShellScriptBin "foot_wrapper" ''${pkgs.foot}/bin/foot $*'';
                }
            ))
            .${name};
        in
          builtins.listToAttrs (map ({
              name,
              applet ? true,
            }: {
              name = name;
              value = build name applet;
            }) [
              {
                name = "launcher";
                applet = false;
              }
              {
                name = "powermenu";
                applet = false;
              }
              {name = "apps";}
              {name = "appsasroot";}
              {name = "battery";}
              {name = "brightness";}
              {name = "mpd";}
              {name = "quicklinks";}
              {name = "screenshot";}
              {name = "volume";}
            ]);
      };
      packages = {
        apps = lib.premade.apps 2 2;
        appsasroot = lib.premade.appsasroot 2 2;
        battery = lib.premade.battery 2 2;
        brightness = lib.premade.brightness 2 2;
        launcher = lib.premade.launcher 2 2;
        mpd = lib.premade.mpd 2 2;
        powermenu = lib.premade.powermenu 2 2;
        quicklinks = lib.premade.quicklinks 2 2;
        screenshot = lib.premade.screenshot 2 2;
        volume = lib.premade.volume 2 2;
      };
    });
}
