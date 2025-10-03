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
              in
              pkgs.mkShell {
                packages = with pkgs; [
                  hugo # Static site generator
                  mask # Task runner
                  nodejs # Node
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
