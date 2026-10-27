{
  lib,
  runCommand,
  personal-blog,
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
  personal-blog -content ${src}/content -out $out
''
