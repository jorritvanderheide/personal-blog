{
  description = "A Nix-flake for the local development environment of my personal blog";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs =
    { nixpkgs, ... }:
    let
      # Define the supported systems
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
      ];

      # Define the development shell for the specified system
      devShellsBySys = builtins.listToAttrs (
        map (system: {
          name = system;
          value = {
            default =
              let
                pkgs = import nixpkgs { inherit system; };

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

                      # Build dependencies
                      buildInputs = [
                        ps.setuptools
                        ps.wheel
                      ];

                      # Runtime dependencies
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
                  hugo # Static site generator
                  mask # Task runner
                  nodejs # Node
                  pythonWithPackages
                ];

                shellHook = ''
                  # If the shell is Fish, start a new shell session
                  if [[ "$SHELL" == *"fish"* ]]; then
                    exec fish
                  fi
                '';
              };
          };
        }) systems
      );
    in
    {
      devShells = devShellsBySys // {
        default = devShellsBySys."${builtins.currentSystem}".default;
      };
    };
}
