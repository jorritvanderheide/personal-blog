{
  description = "BW20 personal blog";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # What the deploy builds (nix/module.nix): the program, and the site
      # it makes from content/.
      packages = forAllSystems (
        pkgs:
        let
          personal-blog = pkgs.callPackage ./nix/package.nix { };
        in
        {
          inherit personal-blog;
          site = pkgs.callPackage ./nix/site.nix {
            inherit personal-blog;
            now = self.lastModified;
            # A working copy with changes has no count: no build number then.
            build = self.revCount or 0;
          };
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.site;
        }
      );

      nixosModules.default = ./nix/module.nix;

      # The program's tests run in its build; the site's build is the real
      # content's, which fails on a post the site can't take.
      checks = forAllSystems (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) personal-blog site;
        module = import ./nix/test.nix {
          inherit pkgs;
          module = self.nixosModules.default;
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            go
            gopls
          ];
          env = {
            CGO_ENABLED = "0";
            GOTOOLCHAIN = "local";
          };
        };
      });

      apps = forAllSystems (pkgs: {
        # The site on http://localhost:8080 (or PERSONAL_BLOG_LISTEN), built
        # again on every request, with the templates read from disk.
        dev = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "personal-blog-dev";
              runtimeInputs = with pkgs; [
                git
                go
              ];
              text = ''
                cd "$(git rev-parse --show-toplevel)"
                export CGO_ENABLED=0 GOTOOLCHAIN=local
                go run . -serve "''${PERSONAL_BLOG_LISTEN:-127.0.0.1:8080}" -dev-assets .
              '';
            }
          );
        };
      });
    };
}
