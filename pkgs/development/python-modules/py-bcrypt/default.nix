{ lib, buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  version = "0.4";
  pname = "py-bcrypt";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-X6E7zlUUaDUNZsSINpSFBXDz2ijWhmu2OLpE/l6r2ng=";
  };

  meta = with lib; {
    maintainers = with maintainers; [ minijackson ];
    description = "bcrypt password hashing and key derivation";
    license = licenses.bsd0;
    homepage = "https://www.mindrot.org/projects/py-bcrypt/";
  };
}
