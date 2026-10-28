{
  lib,
  runCommand,
  personal-blog,
  # The commit count, the build number at the foot of every page
  # (docs/architecture.md, Time). From the flake, not a counter file, so the
  # same commit gives the same site.
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
  personal-blog -content ${src}/content -out $out -build ${toString build}
''
