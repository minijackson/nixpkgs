# It may be useful to expose it outside of the Mobilizon package

{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "cldr-locales";
  version = "2.17.2";

  src = fetchFromGitHub {
    owner = "elixir-cldr";
    repo = "cldr";
    rev = "v${version}";
    sha256 = "1jr54crwm6ayjpvch81gdfh08dxac68cpxvwzqrr9xrv6618j14v";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out
    cp $src/priv/cldr/locales/* $out
  '';
}
