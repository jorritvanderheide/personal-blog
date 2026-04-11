{
  description = "BW20 personal blog";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, self, ... }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
      ];

      forEachSystem = fn: nixpkgs.lib.genAttrs systems (system: fn (import nixpkgs { inherit system; }));

      pythonWithPackages =
        pkgs:
        pkgs.python313.withPackages (
          ps: with ps; [
            pillow
            numpy

            (ps.buildPythonPackage rec {
              pname = "hitherdither";
              version = "0.1.5";

              src = pkgs.fetchFromGitHub {
                owner = "hbldh";
                repo = "hitherdither";
                rev = "v${version}";
                sha256 = "BKbMV3dCbCkHLEpaLrY0YmaWzBFlfnlOnqc7UBs6wjw=";
              };

              pyproject = true;

              buildInputs = [
                ps.setuptools
                ps.wheel
              ];

              propagatedBuildInputs = [
                ps.pillow
                ps.numpy
              ];

              doCheck = false;
            })
          ]
        );
    in
    {
      packages = forEachSystem (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "bw20-blog";
          version = "0.1.0";
          src = self;

          nativeBuildInputs = [
            pkgs.hugo
            pkgs.tailwindcss_4
            (pythonWithPackages pkgs)
          ];

          buildPhase = ''
            hugo --gc --minify
            python3 tools/calculate_size.py --directory public/
          '';

          installPhase = ''
            cp -r public $out
          '';
        };
      });

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.hugo
            pkgs.mask
            pkgs.tailwindcss_4
            (pythonWithPackages pkgs)
          ];

          shellHook = ''
            if [[ "$SHELL" == *"fish"* ]]; then
              exec fish
            fi
          '';
        };
      });
    };
}
