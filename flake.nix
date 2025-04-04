{
  description = "A Nix-flake for the local development environment of my personal blog";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    hugo-theme = builtins.fetchTarball {
      name = "personal-blog-theme";
      url = "https://codeberg.org/bw20/personal-blog-theme/archive/main.tar.gz";
      sha256 = "1j6kn95jqa8j5hjzi5c2xrc26rqx1i7lah1ngq278azj43qw2zd4";
    };
  in {
    devShells."${system}".default = let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
      pkgs.mkShell {
        packages = with pkgs; [
          hugo # Static site generator
          just # Task runner
        ];

        shellHook = ''
          # If the shell is Fish, start a new shell session
          if [[ "$SHELL" == *"fish"* ]]; then
            exec fish
          fi

          # Set the hugo theme
           mkdir -p themes
          ln -snf "${hugo-theme}" themes/personal-blog-theme
        '';
      };
  };
}
