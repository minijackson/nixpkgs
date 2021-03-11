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
  version = "1.0.7";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "framasoft";
    repo = "mobilizon";
    rev = "1.0.7";
    sha256 = "1y7q19svv99cy8j2xylx6rilbfmqh1bpjjfq2q3cwj0a3zrjgpya";
  };

  nativeBuildInputs = [ git cmake gnumake ];

  mixDeps = fetchMixDeps {
    inherit src pname version;
    sha256 = "0w4imdj3gylvvci7yd767v1h5cnih09j1ac2zvgpmjz48ih6afr7";
  };

  preBuild = ''
    cp -a ${cldrLocales}/* $MIX_DEPS_PATH/ex_cldr/priv/cldr/locales/
    touch config/runtime.exs
    cp -a "${js}/libexec/mobilizon/deps/priv/static" ./priv
  '';

  defaultEnvVars = false;
}
