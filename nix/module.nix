self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.bw20-blog;

  # The crawlers layouts/robots.txt turns away, for those that don't read it.
  crawlers = lib.pipe ../layouts/robots.txt [
    builtins.readFile
    (lib.splitString "\n")
    (lib.filter (lib.hasPrefix "User-agent: "))
    (map (lib.removePrefix "User-agent: "))
    (lib.remove "*")
  ];
in
{
  options.services.bw20-blog = {
    enable = lib.mkEnableOption "the BW20 blog";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "personal-blog.packages.\${system}.default";
      description = "The built site.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      example = "bw20.nl";
      description = ''
        Serve the blog with nginx on this domain. It should match `baseURL`
        in hugo.toml, which the feeds and the sitemap link to. TLS is yours
        to add to {option}`services.nginx.virtualHosts.<domain>`, e.g.
        `enableACME` and `forceSSL`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx.enable = true;

    services.nginx.appendHttpConfig = ''
      map $http_user_agent $bw20_blog_crawler {
        default 0;
        "~*(${lib.concatStringsSep "|" crawlers})" 1;
      }
    '';

    # Files in the Nix store all have the same mtime, but nixpkgs' nginx
    # makes ETags from the store path instead, so caching just works.
    services.nginx.virtualHosts.${cfg.domain} = {
      root = cfg.package;

      extraConfig = ''
        error_page 404 /404.html;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header Referrer-Policy "no-referrer" always;
      '';

      locations = {
        "/".extraConfig = ''
          if ($bw20_blog_crawler) {
            return 403;
          }
        '';
        # Everyone may read it, the crawlers it names included.
        "= /robots.txt" = { };
      };
    };
  };
}
