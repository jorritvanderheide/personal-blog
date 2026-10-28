{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.personal-blog;

  # What the deploy builds, as links nginx and the receiver follow. Each moves
  # in one step, when its build is done (docs/architecture.md, Deployment).
  stateDir = "/var/lib/personal-blog";
  site = "${stateDir}/site";
  program = "${stateDir}/program/bin/personal-blog";

  # Every response's headers. nginx drops the server's add_header in a
  # location with an add_header of its own, so such a location repeats them.
  headers = ''
    add_header Content-Security-Policy "default-src 'none'; img-src 'self'; style-src 'self'; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "no-referrer" always;
  '';

  # The 403 for the crawlers robots.txt names, as the build writes it, for
  # every location but robots.txt itself. A glob, so nginx starts before the
  # first deploy, when there is no site yet.
  crawlers = ''
    include ${site}/nginx/location/*.conf;
  '';

  # Run as root after a deploy that built something: nginx reads the build's
  # includes again, the units in deploy.onSuccess start, and the receiver runs
  # the program just built, so it checks posts by the same rules as the build. The socket is started again in case
  # it gave up before the first deploy, when there was no program to start.
  apply = pkgs.writeShellScript "personal-blog-apply" (
    ''
      [ -e ${stateDir}/apply ] || exit 0
      rm ${stateDir}/apply
      systemctl=${config.systemd.package}/bin/systemctl
      $systemctl reload nginx.service
    ''
    + lib.optionalString (cfg.deploy.onSuccess != [ ]) ''
      $systemctl start --no-block ${lib.escapeShellArgs cfg.deploy.onSuccess}
    ''
    + lib.optionalString cfg.receiver.enable ''
      $systemctl reset-failed personal-blog-receiver.socket personal-blog-receiver.service || true
      $systemctl start personal-blog-receiver.socket
      $systemctl try-restart personal-blog-receiver.service
    ''
  );

  # The same hardening for both services: files, the network, and nothing
  # else.
  hardening = {
    CapabilityBoundingSet = "";
    LockPersonality = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
    ];
  };
in
{
  options.services.personal-blog = {
    enable = lib.mkEnableOption "the BW20 personal blog";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "bw20.nl";
      description = ''
        Serve the blog with nginx on this domain. TLS is yours to add to
        {option}`services.nginx.virtualHosts.<domain>`, e.g. `enableACME`
        and `forceSSL`.
      '';
    };

    repository = lib.mkOption {
      type = lib.types.str;
      example = "https://codeberg.org/BW20/personal-blog";
      description = ''
        The blog's repository, over HTTPS, without credentials. The deploy
        asks it for the newest commit, and builds that.
      '';
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "The branch that is published.";
    };

    proxyGroup = lib.mkOption {
      type = lib.types.str;
      default = config.services.nginx.group;
      defaultText = lib.literalExpression "config.services.nginx.group";
      description = "Group of the reverse proxy: only it (and the receiver) may open the receiver's socket.";
    };

    deploy = {
      interval = lib.mkOption {
        type = lib.types.str;
        default = "5min";
        description = ''
          How long after one look at the repository the deploy looks again.
          A push from elsewhere, such as a laptop, is live within this and a
          build. A post the receiver takes starts the deploy at once.
        '';
      };

      onFailure = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "notify-failure@%n.service" ];
        description = ''
          Units to start when a commit doesn't build, such as one that sends
          a notification. Each commit fails once: the deploy doesn't try it
          again, so this isn't started every minute. The site that was
          there stays.
        '';
      };

      onSuccess = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "report-deploy@success.service" ];
        description = ''
          Units to start when a deploy has published a new commit, such as
          one that tells a status page. Not when there was nothing new.
        '';
      };
    };

    receiver = {
      enable = lib.mkEnableOption "the receiver, which takes posts over Micropub and commits them";

      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/personal-blog-receiver-token";
        description = ''
          A file with the token the plugin sends, a long random string.
          systemd hands it to the receiver (`LoadCredential`), so it stays
          out of the Nix store and needn't be readable by the receiver's
          user.
        '';
      };

      pushUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "ssh://git@codeberg.org/BW20/personal-blog.git";
        description = "Where the receiver pushes its commits, over SSH.";
      };

      sshKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/personal-blog-receiver-ssh-key";
        description = ''
          The private key the receiver pushes with: a deploy key with write
          access to this repository only. Handed over as the token is.
        '';
      };

      knownHosts = lib.mkOption {
        type = lib.types.lines;
        default = "";
        example = "codeberg.org ssh-ed25519 AAAA...";
        description = "The forge's SSH host keys, as `known_hosts` lines. The receiver trusts no others.";
      };

      author = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Personal blog receiver <receiver@bw20.nl>";
        description = "The author of the receiver's commits, as Name <address>.";
      };

      socket = lib.mkOption {
        type = lib.types.str;
        default = "/run/personal-blog-receiver/receiver.sock";
        readOnly = true;
        description = "The Unix socket the receiver listens on; it has no TCP port.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # The deploy runs nix build as its own user, which the daemon has to
        # let in. The module can't add it itself: on a host that leaves the
        # list at its default, "*", a value here would replace that, and shut
        # everyone else out.
        assertions = [
          {
            assertion =
              let
                allowed = config.nix.settings.allowed-users;
              in
              builtins.elem "*" allowed || builtins.elem "personal-blog" allowed || builtins.elem "@personal-blog" allowed;
            message = "services.personal-blog: the deploy runs nix build as the user personal-blog. Add it to nix.settings.allowed-users.";
          }
        ];

        users.users.personal-blog = {
          isSystemUser = true;
          group = "personal-blog";
          home = stateDir;
        };
        users.groups.personal-blog = { };

        # Builds the newest commit, and moves the links when both builds are
        # done: the site first, which the program is part of, so a commit
        # that doesn't build changes nothing.
        systemd.services.personal-blog-deploy = {
          description = "Build and publish the newest commit of the BW20 personal blog";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          unitConfig.OnFailure = cfg.deploy.onFailure;
          path = [
            config.nix.package
            pkgs.git
          ];
          environment = {
            REPOSITORY = cfg.repository;
            BRANCH = cfg.branch;
          };

          serviceConfig = hardening // {
            Type = "oneshot";
            User = "personal-blog";
            Group = "personal-blog";
            StateDirectory = "personal-blog";
            StateDirectoryMode = "0755"; # nginx follows the site link
            WorkingDirectory = stateDir;
            ExecStartPost = "+${apply}";
          };

          script = ''
            # A forge that doesn't answer is tried again at the next look,
            # without a failure for every minute it's away.
            if ! line=$(git ls-remote --exit-code "$REPOSITORY" "refs/heads/$BRANCH"); then
              echo "Couldn't ask $REPOSITORY for $BRANCH; trying again later."
              exit 0
            fi
            rev=''${line%%[[:space:]]*}

            [ "$rev" = "$(cat deployed 2>/dev/null)" ] && exit 0
            if [ "$rev" = "$(cat failed 2>/dev/null)" ]; then
              exit 0
            fi

            flake="git+$REPOSITORY?ref=refs/heads/$BRANCH&rev=$rev"
            if ! nix build "$flake#site" --out-link site || ! nix build "$flake#personal-blog" --out-link program; then
              echo "$rev" > failed
              echo "$rev doesn't build; the site that was there stays."
              exit 1
            fi

            echo "$rev" > deployed
            touch apply
            echo "Published $rev."
          '';
        };

        systemd.timers.personal-blog-deploy = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitInactiveSec = cfg.deploy.interval;
          };
        };

        services.nginx.enable = true;

        # Files in the Nix store all have the same mtime, but nixpkgs' nginx
        # makes ETags from the store path instead, so caching just works.
        services.nginx.virtualHosts.${cfg.domain} = {
          root = site;

          # No access log: a blog has no use for its readers' addresses. The
          # build's server includes are the redirects of old slugs.
          extraConfig = ''
            access_log off;
            error_page 404 /404.html;
            ${headers}
            include ${site}/nginx/server/*.conf;
          '';

          locations = {
            # HTML is asked for again each time, and its ETag answers with a
            # 304 when nothing changed: a new post shows at once.
            "/".extraConfig = ''
              expires -1;
              ${crawlers}
            '';

            # Hashed (?v=), so a year is safe: a new file has a new address.
            "/static/".extraConfig = ''
              expires 1y;
              ${crawlers}
            '';

            # Everyone may read it, the crawlers it names included.
            "= /robots.txt" = { };

            # The build's includes are for nginx, not for readers.
            "^~ /nginx/".return = "404";
          };
        };
      }

      (lib.mkIf cfg.receiver.enable {
        assertions =
          map
            (name: {
              assertion = cfg.receiver.${name} != null && cfg.receiver.${name} != "";
              message = "services.personal-blog.receiver.${name} is needed for the receiver.";
            })
            [
              "tokenFile"
              "pushUrl"
              "sshKeyFile"
              "knownHosts"
              "author"
            ];

        users.users.personal-blog-receiver = {
          isSystemUser = true;
          group = "personal-blog-receiver";
          home = "/var/lib/personal-blog-receiver";
        };
        users.groups.personal-blog-receiver = { };

        # systemd owns the socket: only the proxy's group may open it, and the
        # proxy keeps its connection while the receiver restarts after a
        # deploy.
        # A post the receiver pushed is built at once, not at the timer's next
        # look: it writes the time to `pushed` after each push, and a change to
        # that file starts the deploy. A deploy already running takes the start
        # as its own, and a commit that came in during it waits for the timer.
        systemd.paths.personal-blog-pushed = {
          description = "Start the BW20 personal blog's deploy when the receiver has pushed";
          wantedBy = [ "paths.target" ];
          pathConfig = {
            PathChanged = "/var/lib/personal-blog-receiver/pushed";
            Unit = "personal-blog-deploy.service";
          };
        };

        systemd.sockets.personal-blog-receiver = {
          description = "BW20 personal blog receiver socket";
          wantedBy = [ "sockets.target" ];
          listenStreams = [ cfg.receiver.socket ];
          socketConfig = {
            SocketUser = "personal-blog-receiver";
            SocketGroup = cfg.proxyGroup;
            SocketMode = "0660";
          };
        };

        # The program the deploy built, not one from this configuration, so
        # the receiver and the build can't disagree about what breaks the site.
        systemd.services.personal-blog-receiver = {
          description = "BW20 personal blog receiver, which takes posts over Micropub";
          requires = [ "personal-blog-receiver.socket" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "personal-blog-receiver.socket"
          ];
          path = [
            pkgs.git
            pkgs.openssh
          ];

          serviceConfig = hardening // {
            ExecStart = lib.escapeShellArgs [
              program
              "-receive"
              "-listen"
              "systemd"
              "-base-url"
              "https://${cfg.domain}"
              "-push-url"
              cfg.receiver.pushUrl
              "-branch"
              cfg.branch
              "-author"
              cfg.receiver.author
              "-token-file"
              "%d/token"
              "-ssh-key-file"
              "%d/ssh-key"
              "-known-hosts"
              (pkgs.writeText "personal-blog-known-hosts" cfg.receiver.knownHosts)
              "-state"
              "/var/lib/personal-blog-receiver"
            ];
            LoadCredential = [
              "token:${cfg.receiver.tokenFile}"
              "ssh-key:${cfg.receiver.sshKeyFile}"
            ];
            User = "personal-blog-receiver";
            Group = "personal-blog-receiver";
            StateDirectory = "personal-blog-receiver";
            StateDirectoryMode = "0700";
            UMask = "0077";
            Restart = "on-failure";
            RestartPreventExitStatus = 2;
            RestartSec = "5s";
            MemoryDenyWriteExecute = true;
          };
        };

        services.nginx.virtualHosts.${cfg.domain}.locations = {
          # Where the plugin finds the receiver. try_files serves the front
          # page here: index would hand it to "/", without the Link header.
          "= /".extraConfig = ''
            try_files /index.html =404;
            expires -1;
            ${headers}
            add_header Link '</micropub>; rel="micropub"' always;
            ${crawlers}
          '';

          # The post and its images, the largest 20 MB.
          "/micropub" = {
            proxyPass = "http://unix:${cfg.receiver.socket}";
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 21m;
            '';
          };
        };
      })
    ]
  );
}
