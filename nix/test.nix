# Serves the blog with nginx in a VM: its pages, its 404 page, its headers,
# and a 403 for the crawlers robots.txt names, which may still read it.
self:
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "bw20-blog";
  nodes.machine = {
    imports = [ self.nixosModules.default ];
    networking.hosts."127.0.0.1" = [ "blog.test" ];
    services.bw20-blog = {
      enable = true;
      domain = "blog.test";
    };
  };

  testScript = ''
    machine.wait_for_unit("nginx.service")
    machine.wait_for_open_port(80)

    def status(args):
        return machine.succeed(f"curl -s -o /dev/null -w '%{{http_code}}' {args}").strip()

    with subtest("the pages, with their headers"):
        machine.succeed("curl -sf http://blog.test/ | grep -q '<title>'")
        machine.succeed("curl -sf http://blog.test/log/ | grep -q '<title>'")
        headers = machine.succeed("curl -sfI http://blog.test/")
        assert "nosniff" in headers and "no-referrer" in headers, headers

    with subtest("a missing page is a 404, with the site's own page"):
        assert status("http://blog.test/nope/") == "404"
        machine.succeed("curl -s http://blog.test/nope/ | grep -q Composted")

    with subtest("the crawlers in robots.txt get a 403, but may read it"):
        assert status("-A 'Mozilla/5.0 (compatible; GPTBot/1.2)' http://blog.test/") == "403"
        assert status("-A 'ClaudeBot' http://blog.test/log/") == "403"
        assert status("-A 'GPTBot' http://blog.test/robots.txt") == "200"
        assert status("-A 'Mozilla/5.0' http://blog.test/") == "200"
  '';
}
