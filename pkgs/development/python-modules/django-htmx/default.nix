{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools
, wheel
, asgiref
, django
}:

buildPythonPackage rec {
  pname = "django-htmx";
  version = "1.17.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "adamchainz";
    repo = "django-htmx";
    rev = version;
    hash = "sha256-DZOy+bC8XJrKlOKi+xua4WhXGtKXdfIBj2w/hiIKDB8=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    asgiref
    django
  ];

  pythonImportsCheck = [ "django_htmx" ];

  meta = with lib; {
    description = "Extensions for using Django with htmx";
    homepage = "https://github.com/adamchainz/django-htmx";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
