{ lib
, buildPythonPackage
, fetchFromGitHub
, flask
, pytestCheckHook
, pythonOlder
}:

buildPythonPackage rec {
  pname = "flask-paginate";
  version = "2023.10.8";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "lixxu";
    repo = "flask-paginate";
    rev = "refs/tags/v${version}";
    hash = "sha256-QXXuXwMY3CwSv1P5zDK6q/LZfh96/BL3fbdbg53BJ6o=";
  };

  propagatedBuildInputs = [
    flask
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "flask_paginate"
  ];

  pytestFlagsArray = [
    "tests/tests.py"
  ];

  meta = with lib; {
    description = "Pagination support for Flask";
    homepage = "https://github.com/lixxu/flask-paginate";
    changelog = "https://github.com/lixxu/flask-paginate/releases/tag/v${version}";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}
