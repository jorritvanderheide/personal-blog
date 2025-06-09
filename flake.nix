{
  description = "A Nix-flake for the local development environment of my personal blog";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      devShells."${system}".default =
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            hugo # Static site generator
            mask # Task runner
            tailwindcss_4 # CSS framework
          ];

          shellHook = ''
            # If the shell is Fish, start a new shell session
            if [[ "$SHELL" == *"fish"* ]]; then
              exec fish
            fi
          '';
        };
    };
}
