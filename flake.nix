{
  description = "Hammerspoon command palette with optional sources";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs =
    { self, nixpkgs }:
    let
      each = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      packages = each (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.runCommand "CommandPalette.spoon-0.1.0" { } ''
            mkdir -p "$out"
            cp -r ${./init.lua} "$out/init.lua"
            cp -r ${./command_palette} "$out/command_palette"
          '';
        }
      );
      checks = each (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          palette =
            pkgs.runCommand "command-palette-check"
              {
                nativeBuildInputs = [
                  pkgs.lua5_4
                  pkgs.nodejs
                  pkgs.stylua
                ];
              }
              ''
                    stylua --config-path ${./stylua.toml} --check ${./init.lua} ${./command_palette} ${./tests}
                    lua ${./tests/panel.lua} ${./.}
                    lua ${./tests/lifecycle.lua} ${./.}
                lua ${./tests/sources.lua} ${./.}
                    node ${./tests/actions.mjs} ${./command_palette/page/actions.js} ${./command_palette/page/panel.html}
                    touch "$out"
              '';
        }
      );
      devShells = each (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.lua5_4
              pkgs.nodejs
              pkgs.stylua
              pkgs.nixfmt
              pkgs.git
            ];
          };
        }
      );
    };
}
