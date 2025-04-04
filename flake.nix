{
  description = "A Nix-flake for the local development environment of my personal blog";
  inputs = {
    # Specify the Nixpkgs repository version to use for building the development environment
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
  in {
    # Define the development shell for the specified system architecture
    devShells."${system}".default = let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
      pkgs.mkShell {
        packages = with pkgs; [
          hugo
        ];
        # Shell hook that executes when the development environment starts
        shellHook = ''
          # If the shell is Fish, start a new Fish shell session to ensure proper environment setup
          if [[ "$SHELL" == *"fish"* ]]; then
            exec fish
          fi
        '';
      };
  };
}
