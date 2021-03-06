{ stdenv, lib
, makeWrapper, dpkg, fetchurl, autoPatchelfHook
, curl, libkrb5, lttng-ust, libpulseaudio, gtk3, openssl_1_1, icu, webkitgtk, librsvg, gdk-pixbuf, libsoup, glib-networking
}:

stdenv.mkDerivation rec {
  pname = "aws-workspaces";
  version = "3.1.8.1198";

  src = fetchurl {
    # ref https://d3nt0h4h6pmmc4.cloudfront.net/ubuntu/dists/bionic/main/binary-amd64/Packages
    urls = [
      "https://d3nt0h4h6pmmc4.cloudfront.net/ubuntu/dists/bionic/main/binary-amd64/workspacesclient_${version}_amd64.deb"
      "https://web.archive.org/web/20210626165043/https://d3nt0h4h6pmmc4.cloudfront.net/ubuntu/dists/bionic/main/binary-amd64/workspacesclient_${version}_amd64.deb"
    ];
    sha256 = "e784bc4401c2ffaf19f3cc42cb6c6f229c73adba36df49093a1d8cd30c86aaf0";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # Crashes at startup when stripping:
  # "Failed to create CoreCLR, HRESULT: 0x80004005"
  dontStrip = true;

  buildInputs = [
    stdenv.cc.cc.lib
    libkrb5
    curl
    lttng-ust
    libpulseaudio
    gtk3
    openssl_1_1.out
    icu
    webkitgtk
    librsvg
    gdk-pixbuf
    libsoup
    glib-networking
  ];

  unpackPhase = ''
    ${dpkg}/bin/dpkg -x $src $out
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv $out/opt/workspacesclient/* $out/bin

    wrapProgram $out/bin/workspacesclient \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --set GDK_PIXBUF_MODULE_FILE "${librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
      --set GIO_EXTRA_MODULES "${glib-networking.out}/lib/gio/modules"
  '';

  meta = with lib; {
    description = "Client for Amazon WorkSpaces, a managed, secure Desktop-as-a-Service (DaaS) solution";
    homepage = "https://clients.amazonworkspaces.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ]; # TODO Mac support
    maintainers = [ maintainers.mausch ];
  };
}
