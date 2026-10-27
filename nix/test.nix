# The module in VMs, without the network.
#
# deploy: the deploy itself, from a repository on the VM. Building the real
# flake there would need nixpkgs and Go without the network, so the blog in it
# is a stand-in (test/) that writes what the real build does: a first deploy,
# a commit that doesn't build, and one that does again.
#
# site: the real site, built here, as nginx serves it to a reader, and the
# real receiver, which commits a post it takes to a repository on the VM.
{
  pkgs,
  module,
  site,
  personal-blog,
  content,
}:
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

  nodes.deploy = {
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

    systemd.services.deploy-published = {
      serviceConfig.Type = "oneshot";
      script = "touch /tmp/deploy-published";
    };

    services.personal-blog = {
      enable = true;
      domain = "bw20.test";
      repository = "file:///srv/blog.git";
      deploy.onFailure = [ "deploy-failed.service" ];
      deploy.onSuccess = [ "deploy-published.service" ];

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

  nodes.site = {
    imports = [ module ];

    # Where the deploy would have put them. The deploy finds no repository
    # here, and leaves them.
    systemd.tmpfiles.rules = [
      "d /var/lib/personal-blog 0755 personal-blog personal-blog -"
      "L+ /var/lib/personal-blog/site - - - - ${site}"
      "L+ /var/lib/personal-blog/program - - - - ${personal-blog}"
    ];
    environment.systemPackages = [ pkgs.git ];

    services.personal-blog = {
      enable = true;
      domain = "bw20.test";
      repository = "file:///srv/none";

      receiver = {
        enable = true;
        tokenFile = "${pkgs.writeText "token" "secret"}";
        # The sandbox lets it write only to its state directory, so the
        # repository it pushes to is there too: on a host, it pushes over SSH.
        pushUrl = "file:///var/lib/personal-blog-receiver/remote.git";
        sshKeyFile = "${pkgs.writeText "ssh-key" "not a key"}";
        knownHosts = "forge.test ssh-ed25519 AAAAtest";
        author = "Receiver <receiver@bw20.test>";
      };
    };
  };

  testScript = ''
    def get(machine, path, *args):
        return machine.succeed(f"curl -s -H 'Host: bw20.test' {' '.join(args)} http://localhost{path}")

    def status(machine, path, *args):
        return get(machine, path, "-o /dev/null", "-w '%{http_code}'", *args)

    start_all()

    # The deploy.

    def commit(page):
        deploy.succeed(
            f"echo '{page}' > /tmp/work/page.txt",
            "git -C /tmp/work add -A",
            f"git -C /tmp/work -c user.name=t -c user.email=t@t commit -qm '{page}'",
            # Nix reads only a repository its user owns, and git pushes only
            # to one root owns: it changes hands around the push.
            "chown -R root:root /srv/blog.git",
            "git -C /tmp/work push -q /srv/blog.git HEAD:refs/heads/main",
            "chown -R personal-blog:personal-blog /srv/blog.git",
        )

    deploy.wait_for_unit("nginx.service")

    with subtest("nginx starts before the first deploy"):
        deploy.succeed("systemctl is-active personal-blog-receiver.socket")

    deploy.succeed(
        "git init -q --bare -b main /srv/blog.git",
        "git init -q -b main /tmp/work",
        "cp ${standIn}/* /tmp/work/",
    )

    with subtest("a deploy publishes the newest commit"):
        commit("first")
        deploy.succeed("systemctl start personal-blog-deploy.service")
        assert "first" in get(deploy, "/")
        deploy.wait_for_file("/tmp/deploy-published")

    with subtest("the receiver's link"):
        assert 'rel="micropub"' in get(deploy, "/", "-D -", "-o /dev/null")

    with subtest("the build's includes"):
        # nginx reloads after a deploy, and its new workers start a moment
        # later: the redirect shows once they have.
        deploy.wait_until_succeeds(
            "curl -s -H 'Host: bw20.test' -o /dev/null -w '%{http_code}' http://localhost/log/old/ | grep -qx 301",
            timeout=30,
        )
        for want, args in [("403", ["/log/hello/", "-A GPTBot"]), ("404", ["/nginx/server/aliases.conf"])]:
            got = status(deploy, *args)
            assert want in got, f"{args}: {got}, want {want}"

    with subtest("a deploy with nothing new does nothing"):
        deploy.succeed("rm /tmp/deploy-published")
        deploy.succeed("systemctl start personal-blog-deploy.service")
        assert "first" in get(deploy, "/")
        deploy.fail("test -e /tmp/deploy-published")

    with subtest("a commit that doesn't build changes nothing, and fails once"):
        commit("fail")
        deploy.fail("systemctl start personal-blog-deploy.service")
        deploy.wait_for_file("/tmp/deploy-failed")
        assert "first" in get(deploy, "/")
        deploy.succeed("rm /tmp/deploy-failed")
        deploy.succeed("systemctl start personal-blog-deploy.service")
        deploy.fail("test -e /tmp/deploy-failed")

    with subtest("the next commit that builds publishes again"):
        commit("second")
        deploy.succeed("systemctl start personal-blog-deploy.service")
        assert "second" in get(deploy, "/")
        deploy.succeed("systemctl is-active personal-blog-receiver.socket")

    # The real site.

    site.wait_for_unit("nginx.service")

    with subtest("the real site's pages"):
        home = get(site, "/")
        assert "A small, finite website" in home, home
        about = get(site, "/about/")
        assert "<h1>About</h1>" in about, about
        assert "No posts yet." in get(site, "/log/")
        assert "<feed" in get(site, "/feed.xml")

    with subtest("the real site's headers"):
        headers = get(site, "/about/", "-D -", "-o /dev/null")
        assert "default-src 'none'" in headers, headers
        assert "X-Content-Type-Options: nosniff" in headers, headers
        assert "Cache-Control: no-cache" in headers, headers
        assert "micropub" not in headers, headers
        css = site.succeed("grep -o '/static/site.css?v=[0-9a-f]*' /var/lib/personal-blog/site/index.html").strip()
        assert "max-age=31536000" in get(site, css, "-D -", "-o /dev/null")

    with subtest("the real site's crawlers, 404 and includes"):
        assert "403" in status(site, "/about/", "-A GPTBot")
        assert "200" in status(site, "/robots.txt", "-A GPTBot")
        assert "404" in status(site, "/nope/")
        assert "Not here" in get(site, "/nope/")
        assert "404" in status(site, "/nginx/location/crawlers.conf")

    # The real receiver.

    site.succeed(
        "mkdir -p /var/lib/personal-blog-receiver",
        "git init -q --bare -b main /var/lib/personal-blog-receiver/remote.git",
        "git init -q -b main /tmp/work",
        "cp -r ${content} /tmp/work/content",
        "chmod -R u+w /tmp/work",
        "git -C /tmp/work add -A",
        "git -C /tmp/work -c user.name=t -c user.email=t@t commit -qm content",
        "git -C /tmp/work push -q /var/lib/personal-blog-receiver/remote.git HEAD:refs/heads/main",
        "chown -R personal-blog-receiver:personal-blog-receiver /var/lib/personal-blog-receiver",
    )

    def micropub(body, *args):
        site.succeed(f"cat > /tmp/post.json <<'EOF'\n{body}\nEOF")
        return get(site, "/micropub", "-X POST", "-H 'Content-Type: application/json'", "--data-binary @/tmp/post.json", *args)

    token = "-H 'Authorization: Bearer secret'"
    post = '{"type": ["h-entry"], "properties": {"name": ["From the VM"], "summary": ["A test."], "content": ["Said in a VM."], "category": ["tech"], "mp-slug": ["from-the-vm"]}}'

    with subtest("the receiver wants its token"):
        out = micropub(post, "-w ' %{http_code}'")
        assert out.endswith("401"), out

    with subtest("the receiver refuses a post that would break the build"):
        broken = post.replace('"summary": ["A test."], ', "")
        out = micropub(broken, token, "-w ' %{http_code}'")
        assert out.endswith("400") and "missing summary" in out, out

    with subtest("the receiver commits a post"):
        out = micropub(post, token, "-D -", "-o /dev/null")
        assert "202" in out and "Location: https://bw20.test/log/from-the-vm/" in out, out
        assert site.succeed("git -c safe.directory='*' --git-dir /var/lib/personal-blog-receiver/remote.git log -1 --format=%s") == "publish: from-the-vm\n"
        text = site.succeed("git -c safe.directory='*' --git-dir /var/lib/personal-blog-receiver/remote.git show main:content/log/from-the-vm/index.md")
        assert 'generator = "micropub"' in text and "Said in a VM." in text, text
  '';
}
