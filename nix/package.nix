{
  lib,
  buildGoModule,
}:
let
  root = ../.;
in
buildGoModule {
  pname = "personal-blog";
  version = "dev";

  # The program only: everything but content/, so a commit that only changes
  # posts finds it in the store already. The templates under web/ are
  # embedded in it. small-press comes as go.mod pins it.
  src = lib.fileset.toSource {
    inherit root;
    fileset = lib.fileset.unions [
      ../go.mod
      ../go.sum
      (lib.fileset.fileFilter (f: f.hasExt "go") root)
      ../web
    ];
  };

  vendorHash = "sha256-k1ZyQQXc+9daZGlDyzz0WBftJ/USIRcf30V7Ya6jbIk=";

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "The BW20 personal blog's program: builds the site from content/";
    mainProgram = "personal-blog";
    license = lib.licenses.eupl12;
    platforms = lib.platforms.linux;
  };
}
