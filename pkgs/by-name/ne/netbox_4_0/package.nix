{
  lib,
  fetchFromGitHub,
  python3,
  plugins ? ps: [ ],
  extraPatches ? [ ],
  nixosTests,
}:
let
  extraBuildInputs = plugins python3.pkgs;
in
python3.pkgs.buildPythonApplication rec {
  pname = "netbox";
  version = "4.0.6";

  format = "other";

  src = fetchFromGitHub {
    owner = "netbox-community";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-61pJbMWXNFnvWI0z9yWvsutdCAP4VydeceANNw0nKsk=";
  };

  patches = extraPatches;

  propagatedBuildInputs =
    (with python3.pkgs; [
      bleach
      boto3
      django_5
      django-cors-headers
      django-debug-toolbar
      django-filter
      django-graphiql-debug-toolbar
      django-mptt
      django-pglocks
      django-prometheus
      django-redis
      django-rq
      django-tables2
      django-taggit
      django-timezone-field
      djangorestframework
      drf-spectacular
      drf-spectacular-sidecar
      drf-yasg
      dulwich
      swagger-spec-validator # from drf-yasg[validation]
      feedparser
      graphene-django
      jinja2
      markdown
      markdown-include
      netaddr
      pillow
      psycopg2
      pyyaml
      requests
      sentry-sdk
      social-auth-core
      social-auth-app-django
      svgwrite
      tablib
      jsonschema
    ])
    ++ extraBuildInputs;

  buildInputs = with python3.pkgs; [
    mkdocs-material
    mkdocs-material-extensions
    mkdocstrings
    mkdocstrings-python
  ];

  nativeBuildInputs = [ python3.pkgs.mkdocs ];

  postBuild = ''
    PYTHONPATH=$PYTHONPATH:netbox/
    python -m mkdocs build
  '';

  installPhase = ''
    mkdir -p $out/opt/netbox
    cp -r . $out/opt/netbox
    chmod +x $out/opt/netbox/netbox/manage.py
    makeWrapper $out/opt/netbox/netbox/manage.py $out/bin/netbox \
      --prefix PYTHONPATH : "$PYTHONPATH"
  '';

  passthru = {
    # PYTHONPATH of all dependencies used by the package
    pythonPath = python3.pkgs.makePythonPath propagatedBuildInputs;
    gunicorn = python3.pkgs.gunicorn;
    tests = {
      netbox = nixosTests.netbox_4_0;
      inherit (nixosTests) netbox-upgrade;
    };
  };

  meta = {
    homepage = "https://github.com/netbox-community/netbox";
    description = "IP address management (IPAM) and data center infrastructure management (DCIM) tool";
    mainProgram = "netbox";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      minijackson
      n0emis
      raitobezarius
    ];
  };
}
