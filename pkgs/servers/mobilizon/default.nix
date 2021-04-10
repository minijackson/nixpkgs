{ buildMix
, callPackage
, fetchMixDeps
, fetchFromGitLab
, git
, cmake
, gnumake
}:

let
  cldrLocales = callPackage ./cldrLocales.nix {};
  js = callPackage ./js.nix {};
in buildMix rec {
  pname = "mobilizon";
  version = "1.1.0";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "framasoft";
    repo = "mobilizon";
    rev = version;
    sha256 = "1cmqpakjlafsnbk6c1vb6xzi5d2gwfihqxavbznjljk88wr2p4hr";
  };

  nativeBuildInputs = [ git cmake gnumake ];

  mixDeps = fetchMixDeps {
    inherit src pname version;
    sha256 = "0cxpibgm9lfymicprpxa3d5i32lpwkgg107913bvyg53lajfbwpc";
  };

  preBuild = ''
    cp -a ${cldrLocales}/* $MIX_DEPS_PATH/ex_cldr/priv/cldr/locales/
    touch config/runtime.exs
    cp -a "${js}/libexec/mobilizon/deps/priv/static" ./priv
  '';

  defaultEnvVars = false;
}
