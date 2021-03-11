{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.services.mobilizon;

  user = "mobilizon";
  group = "mobilizon";

  settingsFormat = pkgs.formats.elixirConf { };

  runtimeConfig = settingsFormat.generate "mobilizon-runtime.exs" cfg.settings;

  # TODO: make this a globally available function
  package = pkgs.stdenv.mkDerivation rec {
    pname = "${cfg.package.pname}-with-config";
    inherit (cfg.package) version;

    src = cfg.package;

    nativeBuildInputs = with pkgs; [ makeWrapper ];

    dontBuild = true;

    installPhase = ''
      mkdir $out
      cp -a . $out/
      cp ${runtimeConfig} $out/releases/${version}/runtime.exs
      # TODO: in buildMix, probably
      rm $out/releases/COOKIE
      # TODO: in buildMix, probably
      rm $out/bin/${cfg.package.pname}.bat
    '';

    postFixup = ''
      echo "Hello"
      wrapProgram $out/bin/mobilizon --run '. ${secretEnvFile}'
      wrapProgram $out/bin/mobilizon_ctl --run '. ${secretEnvFile}'
    '';
  };

  repoSettings = cfg.settings.":mobilizon"."Mobilizon.Storage.Repo";
  instanceSettings = cfg.settings.":mobilizon".":instance";

  isLocalPostgres =
    repoSettings.adapter.value == "Ecto.Adapters.Postgres" &&
    repoSettings.socket_dir != null;

  dbuser =
    if repoSettings.username != null then repoSettings.username else "mobilizon";

  postgresql = config.services.postgresql.package;
  postgresqlSocketDir = "/var/run/postgresql";

  secretEnvFile = "/var/lib/mobilizon/secret-env.sh";
in
{
  options = {
    services.mobilizon = {
      enable = mkEnableOption
        "Mobilizon federated organization and mobilization platform";

      package = mkOption {
        type = types.package;
        default = pkgs.mobilizon;
        description = ''
          Which mobilizon package to use.
        '';
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = settingsFormat.type;

          options = {
            ":mobilizon" = {

              "Mobilizon.Web.Endpoint" = {
                url.host = mkOption {
                  type = types.str; # todo "elixirOr str" to allow raw elixir values
                  defaultText = ''
                    ":mobilizon".":instance".hostname
                  '';
                  description = ''
                    Domain of the instance
                  '';
                };

                http.port = mkOption {
                  type = types.port;
                  default = 4000;
                  description = ''
                    The port the app listens to
                  '';
                };

                secret_key_base = mkOption {
                  internal = true;
                  default = settingsFormat.lib.mkGetEnv
                    { envVariable = "MOBILIZON_INSTANCE_SECRET"; };
                  description = ''
                    Secret for this instance.

                    Will be automatically generated at first boot (TODO).
                  '';
                };
              };

              "Mobilizon.Web.Auth.Guardian" = {
                secret_key = mkOption {
                  internal = true;
                  default = settingsFormat.lib.mkGetEnv
                    { envVariable = "MOBILIZON_AUTH_SECRET"; };
                  description = ''
                    Secret for this instance's authontication.

                    Will be automatically generated at first boot (TODO).
                  '';
                };
              };

              ":instance" = {
                name = mkOption {
                  type = types.str;
                  description = ''
                    Name of the instance
                  '';
                };

                hostname = mkOption {
                  type = types.str;
                  description = ''
                    Domain of the instance
                  '';
                };

                email_from = mkOption {
                  type = types.str;
                  defaultText = "noreply@\${hostname}";
                  description = ''
                    The address emails will be send with
                  '';
                };

                email_reply_to = mkOption {
                  type = types.str;
                  defaultText = "\${email_from}";
                  description = ''
                    Reply-To for sent emails
                  '';
                };
              };

              "Mobilizon.Storage.Repo" = {
                adapter = mkOption {
                  type = with types; attrsOf str;
                  # TODO: seems mandatory because of postgres extensions
                  default = settingsFormat.lib.mkAtom "Ecto.Adapters.Postgres";
                  description = ''
                    TODO
                    This will be used
                  '';
                };

                socket_dir = mkOption {
                  type = with types; nullOr str;
                  default = postgresqlSocketDir;
                  description = ''
                    Path to the postgres socket directory.

                    Set this to null if you want to connect to a remote database.
                  '';
                };

                username = mkOption {
                  type = with types; nullOr str;
                  default = user;
                  description = ''
                    User used to connect to the database
                  '';
                };

                database = mkOption {
                  type = types.str;
                  default = "mobilizon_prod";
                  description = ''
                    User used to connect to the database
                  '';
                };

              };

            };
          };
        };
        default = { };

        description = ''
          Mobilizon Elixir documentation, see
          <link xlink:href="https://docs.joinmobilizon.org/administration/configure/reference/"/>
          for supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.mobilizon.settings = {
      ":mobilizon" = {
        "Mobilizon.Web.Endpoint" = {
          server = true;
          url.host = mkDefault instanceSettings.hostname;
        };
        ":instance" = {
          registrations_open = mkDefault false;
          demo = mkDefault false;
          email_from = mkDefault "noreply@${instanceSettings.hostname}";
          email_reply_to = mkDefault instanceSettings.email_from;
        };
        "Mobilizon.Storage.Repo" = {
          pool_size = mkDefault 10;
        };
      };

      ":tzdata".":data_dir" = "/var/lib/mobilizon/tzdata/";
    };

    # This somewhat follows upstream's systemd service here:
    # https://framagit.org/framasoft/mobilizon/-/blob/master/support/systemd/mobilizon.service
    systemd.services.mobilizon = {
      description = "Mobilizon federated organization and mobilization platform";

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStartPre = "${package}/bin/mobilizon_ctl migrate";
        ExecStart = "${package}/bin/mobilizon start";
        ExecStop = "${package}/bin/mobilizon stop";

        #EnvironmentFile = [ secretEnvFile ];

        User = user;
        Group = group;

        StateDirectory = "mobilizon";

        PrivateTmp = true;
        ProtectSystem = "full";
        NoNewPrivileges = true;

        ReadWritePaths = mkIf isLocalPostgres postgresqlSocketDir;
      };

      environment = {
        RELEASE_TMP = "/tmp";
      };
    };

    systemd.services.mobilizon-setup-secrets = {
      description = "Mobilizon setup secrets";
      before = [ "mobilizon.service" ];
      wantedBy = [ "mobilizon.service" ];

      script =
        let
          # Taken from here:
          # https://framagit.org/framasoft/mobilizon/-/blob/1.0.7/lib/mix/tasks/mobilizon/instance.ex#L132-133
          genSecret =
            "IO.puts(:crypto.strong_rand_bytes(64)" +
            "|> Base.encode64()" +
            "|> binary_part(0, 64))";

          # Taken from here:
          # https://github.com/elixir-lang/elixir/blob/v1.11.3/lib/mix/lib/mix/release.ex#L499
          genCookie = "IO.puts(Base.encode32(:crypto.strong_rand_bytes(32)))";

          evalElixir = "${package}/bin/mobilizon eval";
        in
        ''
          set -euxo pipefail

          if [ ! -f "${secretEnvFile}" ]; then
            install -m 600 /dev/null "${secretEnvFile}"
            cat > "${secretEnvFile}" <<EOF
          # This file was automatically generated by mobilizon-setup-secrets.service
          export MOBILIZON_AUTH_SECRET='$(${evalElixir} "${genSecret}")'
          export MOBILIZON_INSTANCE_SECRET='$(${evalElixir} "${genSecret}")'
          export RELEASE_COOKIE='$(${evalElixir} "${genCookie}")'
          EOF
          fi
        '';

      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = group;
        StateDirectory = "mobilizon";
      };
    };

    systemd.services.mobilizon-postgresql = mkIf isLocalPostgres {
      description = "Mobilizon PostgreSQL setup";

      after = [ "postgresql.service" ];
      before = [ "mobilizon.service" "mobilizon-setup-secrets.service" ];
      wantedBy = [ "mobilizon.service" ];

      script =
        let
          pgSu =
            "${pkgs.util-linux}/bin/runuser -u ${config.services.postgresql.superUser}";
          psql = "${pgSu} -- ${postgresql}/bin/psql";
        in
        ''
          ${psql} "${repoSettings.database}" -c "\
            CREATE EXTENSION IF NOT EXISTS postgis; \
            CREATE EXTENSION IF NOT EXISTS pg_trgm; \
            CREATE EXTENSION IF NOT EXISTS unaccent;"
        '';

      serviceConfig.Type = "oneshot";
    };

    services.postgresql = mkIf isLocalPostgres {
      enable = true;
      ensureDatabases = [ repoSettings.database ];
      ensureUsers = [
        {
          name = dbuser;
          ensurePermissions = {
            "DATABASE ${repoSettings.database}" = "ALL PRIVILEGES";
          };
        }
      ];
      extraPlugins = with postgresql.pkgs; [ postgis ];
    };

    users.users.${user} = {
      description = "Mobilizon daemon user";
      group = group;
      isSystemUser = true;
    };

    users.groups.${group} = { };

    # So that we have the `mobilizon` and `mobilizon_ctl` commands
    environment.systemPackages = [ package ];
  };
}
