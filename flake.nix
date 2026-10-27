{
  description = "BW20 personal blog";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  # The packages the deploy builds, personal-blog (the program) and site,
  # come with the code (docs/architecture.md, Running).
  outputs =
    { self, nixpkgs }:
    {
      nixosModules.default = ./nix/module.nix;

      checks.x86_64-linux.module = import ./nix/test.nix {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        module = self.nixosModules.default;
      };
    };
}
