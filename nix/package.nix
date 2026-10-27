{
  lib,
  buildGoModule,
  git,
}:
let
  root = ../.;
in
buildGoModule {
  pname = "personal-blog";
  version = "dev";

  # The program only: everything but content/, so a commit that only changes
  # posts finds it in the store already. The templates under web/ are
  # embedded in it.
  src = lib.fileset.toSource {
    inherit root;
    fileset = lib.fileset.unions [
      ../go.mod
      ../go.sum
      (lib.fileset.fileFilter (f: f.hasExt "go") root)
      ../web
    ];
  };

  vendorHash = "sha256-pRmtJsS55ntxO0Hs3Ig2EPTB/pnYN5dVkUZ7MW7Zhps=";

  # The receiver's tests run git against a repository on disk.
  nativeCheckInputs = [ git ];

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
