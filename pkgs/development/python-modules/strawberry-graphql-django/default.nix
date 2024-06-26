{ lib
, buildPythonPackage
, fetchFromGitHub
, poetry-core
, setuptools
, wheel
, asgiref
, django
, strawberry-graphql
, django-debug-toolbar
, django-choices-field
}:

buildPythonPackage rec {
  pname = "strawberry-django";
  version = "0.39.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "strawberry-graphql";
    repo = "strawberry-django";
    rev = "v${version}";
    hash = "sha256-p5J8VzVjamqKGivUZ60wcuNwSPNU2oAvihjBE5cmmJw=";
  };

  nativeBuildInputs = [
    poetry-core
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    asgiref
    django
    strawberry-graphql
  ];

  passthru.optional-dependencies = {
    debug-toolbar = [
      django-debug-toolbar
    ];
    enum = [
      django-choices-field
    ];
  };

  pythonImportsCheck = [ "strawberry_django" ];

  meta = with lib; {
    description = "Strawberry GraphQL Django extension";
    homepage = "https://github.com/strawberry-graphql/strawberry-django";
    changelog = "https://github.com/strawberry-graphql/strawberry-django/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
