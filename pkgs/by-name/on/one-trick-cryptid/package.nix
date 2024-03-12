{ lib
, stdenv
, rustPlatform
, fetchzip
, cargo
, pkg-config
, python3
, rustc
, alsa-lib
, libglvnd
, libjack2
, libX11
, libXcursor
, libxcb
, xcbutilwm
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "one-trick-cryptid";
  version = "1.0.1";

  src = fetchzip {
    url = "https://punklabs.com/content/projects/ot-cryptid/downloads/OneTrick-CRYPTID-${finalAttrs.version}-Source.zip";
    hash = "sha256-PTI9bNruqY34fdg8t2PUGTvPeZOumA0xpkr806vtb6U=";
    stripRoot = false;
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "assert_no_alloc-1.1.2" = "sha256-kCwtn0uONDTlDqfCpYtjB3spYM89qWjkzUOdcGjtY3c=";
      "baseview-0.1.0" = "sha256-QAkOTdA5krZPOUs7ExTVGfqK+sxG2A4H87GZgDl2LpU=";
      "clap-sys-0.3.0" = "sha256-svq9DMqzKVZCU07FiOIsdCt78BJctwlPobSlNZGeBxQ=";
      "egui-baseview-0.2.0" = "sha256-JingnLkyDq2yy+rktqGlEUg6b0VZvX1oXhnkYaKABEQ=";
      "faust-types-0.1.0" = "sha256-23S5xAu+ZBQ6c2EEUFigV6XKDUzYycGfZOJiTwWy3ag=";
      "nih_plug-0.0.0" = "sha256-3DCQVhbT+GSxNJ1Shn0KDATs09O6EzuntY4L2x6xldU=";
      # "nih_plug_derive-0.0.0" = "";
      # "nih_plug_egui-0.1.0" = "";
      "reflink-0.1.3" = "sha256-1o5d/mepjbDLuoZ2/49Bi6sFgVX4WdCuhGJkk8ulhcI=";
      "vst3-com-0.1.0" = "sha256-tKWEmJR9aRpfsiuVr0K8XXYafVs+CzqCcP+Ea9qvZ7Y=";
    };
  };

  # Update the Cargo.lock file,
  # because there is two different baseview versions in the upstream one.
  # Probably because one dependant of baseview was added after another.
  patches = [ ./update-cargo-lock.patch ];
  # TODO: fix errors due to updates

  nativeBuildInputs = [
    cargo
    pkg-config
    python3
    rustc
    rustPlatform.cargoSetupHook
  ];

  buildInputs = [
    alsa-lib
    libglvnd
    libjack2
    libX11
    libXcursor
    libxcb
    xcbutilwm
  ];

  buildPhase = ''
    runHook preBuild

    cargo xtask bundle onetrick_cryptid --release

    runHook preBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/vst3 $out/lib/clap
    cp -R "target/bundled/OneTrick CRYPTID" $out/bin
    cp -R "target/bundled/OneTrick CRYPTID.clap" $out/lib/clap
    cp -R "target/bundled/OneTrick CRYPTID.vst3" $out/lib/vst3

    runHook postInstall
  '';

  meta = with lib; {
    description = "A hybrid drum synth modeling gritty lofi beats without sampling.";
    homepage = "https://punklabs.com/ot-cryptid";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ minijackson ];
    mainProgram = "OneTrick CRYPTID";
    inherit (rustc.meta) platforms;
  };
})
