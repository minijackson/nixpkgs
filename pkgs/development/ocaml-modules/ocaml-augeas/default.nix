{ lib
, stdenv
, fetchgit
, autoreconfHook
, findlib
, ocaml
, ocamlbuild
, pkg-config
, augeas
, libxml2
}:

stdenv.mkDerivation rec {
  pname = "ocaml${ocaml.version}-augeas";
  version = "0.6";

  src = fetchgit {
    url = "git://git.annexia.org/ocaml-augeas.git";
    rev = "v${version}";
    hash = "sha256-NAraRiUKXUhem26a6g1DM46R/R2Pjm7BFuB+f4x+1Bg=";
  };

  nativeBuildInputs = [ autoreconfHook findlib ocaml ocamlbuild pkg-config ];
  buildInputs = [ augeas libxml2 ];

  postPatch = ''
    # -Werror fails with newer compiler versions
    sed -i 's/-Werror//' Makefile.in
  '';

  preInstall = ''
    mkdir -p $OCAMLFIND_DESTDIR
  '';

  meta = with lib; {
    description = "";
    homepage = "https://people.redhat.com/~rjones/augeas/";
    license = licenses.lgpl21Only;
    maintainers = with maintainers; [ minijackson ];
    mainProgram = "ocaml-augeas";
    platforms = platforms.all;
  };
}
