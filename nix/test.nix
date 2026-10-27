# The module in a VM, without the network. The blog is a stand-in (test/),
# in a repository on the VM itself: a first deploy, nginx serving it with the
# old site's rules, a commit that doesn't build, and one that does again.
{ pkgs, module }:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  standIn = pkgs.runCommand "personal-blog-stand-in" { } ''
    mkdir $out
    cp ${./test/program.sh} $out/program.sh
    cp ${./test/site.sh} $out/site.sh
    substitute ${./test/flake.nix} $out/flake.nix \
      --replace-fail @system@ ${system} \
      --replace-fail @busybox@ ${pkgs.busybox}
  '';
in
pkgs.testers.runNixOSTest {
  name = "personal-blog";

  nodes.machine = {
    imports = [ module ];

    # The stand-in's builder is busybox by its path, not a dependency, so
    # builds run outside the sandbox. Nothing to substitute without the
    # network.
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      sandbox = false;
      substituters = pkgs.lib.mkForce [ ];
    };
    virtualisation.additionalPaths = [
      pkgs.busybox
      standIn
    ];
    environment.systemPackages = [ pkgs.git ];

    systemd.services.deploy-failed = {
      serviceConfig.Type = "oneshot";
      script = "touch /tmp/deploy-failed";
    };

    services.personal-blog = {
      enable = true;
      domain = "bw20.test";
      repository = "file:///srv/blog.git";
      deploy.onFailure = [ "deploy-failed.service" ];

      receiver = {
        enable = true;
        tokenFile = "${pkgs.writeText "token" "secret"}";
        pushUrl = "ssh://git@forge.test/blog.git";
        sshKeyFile = "${pkgs.writeText "ssh-key" "not a key"}";
        knownHosts = "forge.test ssh-ed25519 AAAAtest";
        author = "Receiver <receiver@bw20.test>";
      };
    };
  };

  testScript = ''
    def commit(page):
        machine.succeed(
            f"echo '{page}' > /tmp/work/page.txt",
            "git -C /tmp/work add -A",
            f"git -C /tmp/work -c user.name=t -c user.email=t@t commit -qm '{page}'",
            # Nix reads only a repository its user owns, and git pushes only
            # to one root owns: it changes hands around the push.
            "chown -R root:root /srv/blog.git",
            "git -C /tmp/work push -q /srv/blog.git HEAD:refs/heads/main",
            "chown -R personal-blog:personal-blog /srv/blog.git",
        )

    def get(path, *args):
        return machine.succeed(f"curl -s -H 'Host: bw20.test' {' '.join(args)} http://localhost{path}")

    machine.wait_for_unit("nginx.service")

    with subtest("nginx starts before the first deploy"):
        machine.succeed("systemctl is-active personal-blog-receiver.socket")

    machine.succeed(
        "git init -q --bare -b main /srv/blog.git",
        "git init -q -b main /tmp/work",
        "cp ${standIn}/* /tmp/work/",
    )

    with subtest("a deploy publishes the newest commit"):
        commit("first")
        machine.succeed("systemctl start personal-blog-deploy.service")
        assert "first" in get("/")

    with subtest("headers"):
        headers = get("/", "-D -", "-o /dev/null")
        assert "script-src" not in headers and "default-src 'none'" in headers, headers
        assert "X-Content-Type-Options: nosniff" in headers, headers
        assert 'rel="micropub"' in headers, headers
        assert "default-src 'none'" in get("/log/hello/", "-D -", "-o /dev/null")

    with subtest("the build's includes"):
        assert "301" in get("/log/old/", "-o /dev/null", "-w '%{http_code}'")
        assert "403" in get("/log/hello/", "-A GPTBot", "-o /dev/null", "-w '%{http_code}'")
        assert "200" in get("/robots.txt", "-A GPTBot", "-o /dev/null", "-w '%{http_code}'")
        assert "404" in get("/nope/", "-o /dev/null", "-w '%{http_code}'")
        assert "not here" in get("/nope/")

    with subtest("a deploy with nothing new does nothing"):
        machine.succeed("systemctl start personal-blog-deploy.service")
        assert "first" in get("/")

    with subtest("a commit that doesn't build changes nothing, and fails once"):
        commit("fail")
        machine.fail("systemctl start personal-blog-deploy.service")
        machine.wait_for_file("/tmp/deploy-failed")
        assert "first" in get("/")
        machine.succeed("rm /tmp/deploy-failed")
        machine.succeed("systemctl start personal-blog-deploy.service")
        machine.fail("test -e /tmp/deploy-failed")

    with subtest("the next commit that builds publishes again"):
        commit("second")
        machine.succeed("systemctl start personal-blog-deploy.service")
        assert "second" in get("/")
        machine.succeed("systemctl is-active personal-blog-receiver.socket")
  '';
}
