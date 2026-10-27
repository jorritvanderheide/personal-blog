{
  lib,
  runCommand,
  personal-blog,
  # The last commit's time, and the commit count: what fading and the build
  # number go by (docs/architecture.md, Time). Not the clock: a Nix build is
  # pure, so the same commit gives the same site.
  now,
  build,
}:
let
  # content/ only, so the site is built again when a post changes, and the
  # program when the code does.
  src = lib.fileset.toSource {
    root = ../.;
    fileset = ../content;
  };
in
runCommand "site" { nativeBuildInputs = [ personal-blog ]; } ''
  personal-blog -content ${src}/content -out $out -now ${toString now} -build ${toString build}
''
