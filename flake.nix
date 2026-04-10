{
  description = "Local development environment for my personal blog";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
      ];

      forEachSystem = fn: nixpkgs.lib.genAttrs systems (system: fn (import nixpkgs { inherit system; }));
    in
    {
      devShells = forEachSystem (pkgs: {
        default =
          let
            pythonWithPackages = pkgs.python313.withPackages (
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
          pkgs.mkShell {
            packages = with pkgs; [
              hugo
              mask
              tailwindcss_4
              pythonWithPackages
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
