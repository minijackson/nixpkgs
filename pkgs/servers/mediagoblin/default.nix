{ python3, fetchFromSavannah }:

with python3.pkgs;

buildPythonApplication rec {
  pname = "mediagoblin";
  version = "0.11.0";

  src = fetchFromSavannah {
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-NHF9PO7wYr0IFz9xvdLW0sFlEgngiWRpufhqBqVf2ck=";
  };

  patches = [
    ./relax-dependencies.patch
    #./celery-5.patch
  ];

  propagatedBuildInputs = [
    PasteDeploy
    PyLD
    alembic
    celery
    configobj
    email_validator
    exifread
    gst-python
    itsdangerous
    jinja2
    jsonschema
    lxml
    markdown
    oauthlib
    pasteScript
    pillow
    py-bcrypt
    pygobject3
    pytest-xdist
    python-dateutil
    py3exiv2
    soundfile
    sphinx
    sqlalchemy
    unidecode
    webtest
    werkzeug
    wtforms
  ];

  doCheck = false;
}
