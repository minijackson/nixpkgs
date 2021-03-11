{ stdenv, lib, yarn, mkYarnPackage, mobilizon, ncurses, imagemagick }:

mkYarnPackage rec {

  src = stdenv.mkDerivation {
    name = "mobilizon-js-src";

    src = "${mobilizon.src}/js";

    phases = [ "unpackPhase" "patchPhase" "installPhase" ];

    patches = [
      # Due to the unsupported "resolution" parameter of "package.json"
      ./fix-yarn-lock.patch
      # Don't know why
      ./fix-vue-config.patch
    ];

    installPhase = ''
      mkdir $out
      cp -a . $out/
    '';
  };

  packageJSON = "${src}/package.json";
  yarnLock = "${src}/yarn.lock";

  buildPhase = ''
    # Tests cannot find the functions of the testing framework
    rm -r ./deps/mobilizon/tests
    yarn run build
  '';

  nativeBuildInputs = [ ncurses imagemagick ];
}
