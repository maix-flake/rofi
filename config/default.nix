setPackages: {
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
with builtins;
with lib; let
  themes = pkgs.stdenv.mkDerivation {
    name = "rofi-themes";
    src = inputs.rofi-themes;
    buildPhase = ''
      ls -la .
      patch powermenu/type-1/powermenu.sh <${../powermenu.patch}
      patch powermenu/type-2/powermenu.sh <${../powermenu.patch}
      patch powermenu/type-3/powermenu.sh <${../powermenu.patch}
      patch powermenu/type-4/powermenu.sh <${../powermenu.patch}
      patch powermenu/type-5/powermenu.sh <${../powermenu.patch}
      patch powermenu/type-6/powermenu.sh <${../powermenu.patch}
      substituteInPlace $(${pkgs.findutils}/bin/find . -name '*.rasi' -print) --replace-quiet 'launchers' 'launcher'
      substituteInPlace $(${pkgs.findutils}/bin/find . -name '*.rasi' -print) --replace-quiet '~/.config/rofi/' '@out@/share/rofi/'
      substituteInPlace $(${pkgs.findutils}/bin/find . -name '*.rasi' -print) --replace-quiet '$HOME/.config/rofi/' '@out@/share/rofi/'
      ${pkgs.findutils}/bin/find . -type l | while read symlink; do
        target=$(readlink "$symlink");
        new_target="''${target//launchers/launcher}";
        if [[ "$target" != "$new_target" ]]; then
          ln -sfn "$new_target" "$symlink";
          echo "Updated: $symlink -> $new_target";
        fi
      done

      substituteInPlace $(${pkgs.findutils}/bin/find . -name '*.sh' -print) \
       --replace-quiet "\''${polkit_cmd} alacritty -e" '${getExe config.rofi.terminalPackage} ''${polkit_cmd}' \
       --replace-quiet "theme='style-1'" ""                                                                    \
       --replace-quiet "rofi \\" "${getExe config.rofi.package} \\"                                            \
       --replace-quiet "rofi -" "${getExe config.rofi.package} -"                                              \
       --replace-quiet '"$HOME"/.config/rofi/' '@out@/share/rofi/'                                             \
       --replace-quiet '$HOME/.config/rofi/' '@out@/share/rofi/'                                               \
       --replace-quiet '`hostname`' '`${pkgs.busybox}/bin/hostname`'                                           \
       --replace-quiet 'acpi' '${pkgs.acpi}/bin/acpi'                                                          \
       --replace-quiet 'alacritty -e' "${getExe config.rofi.terminalPackage}"                                  \
       --replace-quiet 'amixer' "${pkgs.alsa-utils}/bin/amixer"                                                \
       --replace-quiet 'exit_cmd' "${getExe config.rofi.exitPackage}"                                          \
       --replace-quiet 'launchers' 'launcher'                                                                  \
       --replace-quiet 'lock_cmd' "${getExe config.rofi.lockPackage}"                                          \
       --replace-quiet 'mpd' "${pkgs.mpd}/bin/mpd"                                                             \
       --replace-quiet 'mpc' "${pkgs.mpc-cli}/bin/mpc"                                                         \
       --replace-quiet 'notify-send' '${pkgs.libnotify}/bin/notify-send'                                       \
       --replace-quiet 'pavucontrol' "${pkgs.pavucontrol}/bin/pavucontrol"                                     \
       --replace-quiet 'powertop' "${pkgs.powertop}/bin/powertop"                                              \
       --replace-quiet 'source "$HOME"/.config/rofi/applets/shared/theme.bash' ""                              \
       --replace-quiet 'systemctl' "${pkgs.systemdMinimal}/bin/systemctl"                                      \
       --replace-quiet 'theme="$type/$style"' ""                                                               \
       --replace-quiet 'uptime -p' '${pkgs.procps}/bin/uptime -p'                                              \
       --replace-quiet 'xfce4-power-manager-settings' "${getExe config.rofi.powermanagerPackage}"              \
       --replace-quiet 'xfce4-settings-manager' "${getExe config.rofi.settingsPackage}"                        \
       --replace-quiet '~/.config/rofi/' '@out@/share/rofi/'                                                   \
    '';
    installPhase = ''
      mkdir -p $out/share/
      cp -r . $out/share/rofi
      substituteInPlace $(${pkgs.findutils}/bin/find $out -name '*.rasi' -print) --subst-var out
      substituteInPlace $(${pkgs.findutils}/bin/find $out -name '*.sh' -print) --subst-var out
      mv $out/share/rofi/launchers $out/share/rofi/launcher
    '';
  };
  modOptions = name: packages: ty: {
    ${name} = {
      enable = lib.mkEnableOption "${name}";
      theme = mkOption {
        type = types.number;
        description = "Select which type to use for the ${name} rofi command";
        default = 1;
      };
      style = mkOption {
        type = types.number;
        description = "Select which style to use for the ${name} rofi command";
        default = 1;
      };
      packages = mkOption {
        type = let
          packagesList = attrsToList packages;
          packagesMod =
            map ({
              name,
              value,
            }: {
              inherit name;
              value = mkOption {
                type = types.package;
                default = value;
                description = "the default package for the ${name} command";
              };
            })
            packagesList;
          submodOptions = {options = listToAttrs packagesMod;};
        in
          types.submodule submodOptions;
        default = packages;
      };
    };
  };
  mkOptions = def: {
    options = {
      rofi =
        {
          lockPackage = mkOption {
            type = types.package;
            description = "A package that will spawn a terminal the arguments will be the cmd to run";
            default = pkgs.writeShellScriptBin "lock-noop" ''${pkgs.libnotify}/bin/notify-send 'set a lock command in the nix option `config.rofi.lockPacakge`' '';
          };
          exitPackage = mkOption {
            type = types.package;
            description = "A package that will spawn a terminal the arguments will be the cmd to run";
            default = pkgs.writeShellScriptBin "exit-noop" ''${pkgs.libnotify}/bin/notify-send 'set a exit command in the nix option `config.rofi.exitPacakge`' '';
          };
          terminalPackage = mkOption {
            type = types.package;
            description = "A package that will spawn a terminal the arguments will be the cmd to run";
            default = pkgs.writeShellScriptBin "term-launch-noop" ''echo $*'';
          };
          powermanagerPackage = mkOption {
            type = types.package;
            description = "The powermanager package to use";
            default = pkgs.writeShellScriptBin "powermanger-noop" ''${pkgs.libnotify}/bin/notify-send "please install a powermanager like 'xfce4-power-manager-settings'"'';
          };
          settingsPackage = mkOption {
            type = types.package;
            description = "The powermanager package to use";
            default = pkgs.writeShellScriptBin "settings-noop" ''${pkgs.libnotify}/bin/notify-send "please install a settings app like 'xfce4-power-manager-settings'"'';
          };
          package = mkOption {
            type = types.package;
            default = pkgs.rofi;
            description = "The rofi pacakges to use";
          };
          applet = foldl' (x: y: x // y) {} (map ({
            name,
            packages ? {},
            type ? "standalone",
          }: (modOptions name packages type))
          (filter ({type ? "standalone", ...}: type == "applet") def));
        }
        // (foldl' (x: y: x // y) {} (map ({
          name,
          packages ? {},
          type ? "standalone",
        }: (modOptions name packages type))
        (filter ({type ? "standalone", ...}: type == "standalone") def)));
    };
  };
  mkConfig = let
    enabled = filter (a: a.value.enable) (
      (map (a: a // {type = "applet";}) (attrsToList config.rofi.applet))
      ++ [
        {
          name = "powermenu";
          value = config.rofi.powermenu;
          type = "standalone";
        }
        {
          name = "launcher";
          value = config.rofi.launcher;
          type = "standalone";
        }
      ]
    );
    mkSingle = name: ty: theme: style: packages: (
      let
        scriptPath =
          if ty == "standalone"
          then "${themes}/share/rofi/${name}/type-${toString theme}/${toString name}.sh"
          else "${themes}/share/rofi/applets/bin/${toString name}.sh";
        computedTheme =
          if ty == "standalone"
          then "theme='style-${toString style}'"
          else "theme='${themes}/share/rofi/applets/type-${toString theme}/style-${toString style}.rasi'";
      in
        pkgs.writeShellScriptBin "rofi-${name}" ''
          export PATH="${concatStringsSep ":" (map (p: "${p}/bin/") (attrValues packages))}:$PATH"
          ${computedTheme} ${scriptPath}
        ''
    );
    built =
      map
      (val: {${val.name} = mkSingle val.name val.type val.value.theme val.value.style val.value.packages;})
      enabled;
  in
    setPackages (foldl' (x: y: x // y) {} built);
  mkReturnVal = names: ((mkOptions names) // mkConfig);
in
  mkReturnVal [
    {name = "powermenu";}
    {name = "launcher";}
    {
      name = "battery";
      type = "applet";
    }
    {
      name = "brightness";
      type = "applet";
    }
    {
      name = "volume";
      type = "applet";
    }
    {
      name = "mpd";
      type = "applet";
    }
    {
      name = "apps";
      type = "applet";
    }
    {
      name = "appsasroot";
      type = "applet";
    }
    {
      name = "screenshot";
      type = "applet";
    }
    {
      name = "quicklinks";
      type = "applet";
    }
  ]
