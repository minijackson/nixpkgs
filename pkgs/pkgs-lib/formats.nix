{ lib, pkgs }:
rec {

  /*

  Every following entry represents a format for program configuration files
  used for `settings`-style options (see https://github.com/NixOS/rfcs/pull/42).
  Each entry should look as follows:

    <format> = <parameters>: {
      #        ^^ Parameters for controlling the format

      # The module system type most suitable for representing such a format
      # The description needs to be overwritten for recursive types
      type = ...;

      # generate :: Name -> Value -> Path
      # A function for generating a file with a value of such a type
      generate = ...;

    });
  */


  json = {}: {

    type = with lib.types; let
      valueType = nullOr (oneOf [
        bool
        int
        float
        str
        (attrsOf valueType)
        (listOf valueType)
      ]) // {
        description = "JSON value";
      };
    in valueType;

    generate = name: value: pkgs.runCommandNoCC name {
      nativeBuildInputs = [ pkgs.jq ];
      value = builtins.toJSON value;
      passAsFile = [ "value" ];
    } ''
      jq . "$valuePath"> $out
    '';

  };

  # YAML has been a strict superset of JSON since 1.2
  yaml = {}:
    let jsonSet = json {};
    in jsonSet // {
      type = jsonSet.type // {
        description = "YAML value";
      };
    };

  ini = { listsAsDuplicateKeys ? false, ... }@args: {

    type = with lib.types; let

      singleIniAtom = nullOr (oneOf [
        bool
        int
        float
        str
      ]) // {
        description = "INI atom (null, bool, int, float or string)";
      };

      iniAtom =
        if listsAsDuplicateKeys then
          coercedTo singleIniAtom lib.singleton (listOf singleIniAtom) // {
            description = singleIniAtom.description + " or a list of them for duplicate keys";
          }
        else
          singleIniAtom;

    in attrsOf (attrsOf iniAtom);

    generate = name: value: pkgs.writeText name (lib.generators.toINI args value);

  };

  toml = {}: json {} // {
    type = with lib.types; let
      valueType = oneOf [
        bool
        int
        float
        str
        (attrsOf valueType)
        (listOf valueType)
      ] // {
        description = "TOML value";
      };
    in valueType;

    generate = name: value: pkgs.runCommandNoCC name {
      nativeBuildInputs = [ pkgs.remarshal ];
      value = builtins.toJSON value;
      passAsFile = [ "value" ];
    } ''
      json2toml "$valuePath" "$out"
    '';

  };

  elixirConf = { elixir ? pkgs.elixir }:
    with lib; let
      toElixir = value: with builtins;
        if value == null then "nil" else
        if value == true then "true" else
        if value == false then "false" else
        if isInt value || isFloat value then toString value else
        if isString value then string value else
        if isAttrs value then attrs value else
        if isList value then list value else
        abort "formats.elixirConf: should never happen (value = ${value})";

      escapeElixir = escape [ "\\" "#" "\"" ];
      string = value: "\"${escapeElixir value}\"";

      attrs = set:
        if set ? _elixirType then specialType set
        else
          let
            toKeyword = name: value: "${name}: ${toElixir value}";
            keywordList = concatStringsSep ", " (mapAttrsToList toKeyword set);
          in
          "[" + keywordList + "]";

      listContent = values: concatStringsSep ", " (map toElixir values);

      list = values: "[" + (listContent values) + "]";

      specialType = { value, _elixirType }:
        if _elixirType == "raw" then value else
        if _elixirType == "atom" then value else
        if _elixirType == "map" then elixirMap value else
        if _elixirType == "tuple" then tuple value else
        abort "formats.elixirConf: should never happen (_elixirType = ${_elixirType})";

      elixirMap = set:
        let
          toEntry = { name, value }: "${toElixir name} => ${toElixir value}";
          entries = concatStringsSep ", " (mapAttrsToList toEntry set);
        in
        "%{" + entries + "}";

      tuple = values: "{" + (listContent values) + "}";

      toConf = values:
        let
          keyConfig = rootKey: key: value:
            "config ${rootKey}, ${key}, ${toElixir value}";
          keyConfigs = rootKey: values: mapAttrsToList (keyConfig rootKey) values;
          rootConfigs = flatten (mapAttrsToList keyConfigs values);
        in
        ''
          import Config

          ${concatStringsSep "\n" rootConfigs}
        '';
    in
    {
      type = with lib.types; let
        valueType = nullOr
          (oneOf [
            bool
            int
            float
            str
            (attrsOf valueType)
            (listOf valueType)
          ]) // {
          description = "Elixir value";
        };
      in
      attrsOf (attrsOf (valueType));

      lib =
        let
          mkRaw = value: {
            inherit value;
            _elixirType = "raw";
          };

          mkGetEnv = { envVariable, fallback ? null }:
            mkRaw "System.get_env(${toElixir envVariable}, ${toElixir fallback})";
        in
        {
          inherit mkRaw mkGetEnv;

          mkAtom = value: {
            inherit value;
            _elixirType = "atom";
          };

          mkTuple = value: {
            inherit value;
            _elixirType = "tuple";
          };

          mkMap = value: {
            inherit value;
            _elixirType = "map";
          };

        };

      generate = name: value: pkgs.runCommandNoCC name
        {
          value = toConf value;
          passAsFile = [ "value" ];
          nativeBuildInputs = [ elixir pkgs.glibc.bin ];
        } ''
        cp "$valuePath" "$out"
        mix format "$out"
      '';
    };

}
