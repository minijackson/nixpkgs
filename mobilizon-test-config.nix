{ config, pkgs, ... }:

{
  fileSystems."/".label = "vmdisk";
  networking.hostName = "vmHost";

  services.mobilizon = with (pkgs.formats.elixirConf { }).lib; {
    enable = true;
    settings = {
      ":mobilizon" = {
        ":instance" = {
          name = "Test Mobilizon";
          hostname = "localhost";
        };

        "Mobilizon.Service.ResourceProviders" = {
          types = {
            pad = mkAtom ":etherpad";
            calc = mkAtom ":ethercalc";
            visio = mkAtom ":jitsi";
          };

          providers = mkMap {
            "etherpad" = "https://etherpad.wikimedia.org/p/";
            "ethercalc" = "https://ethercalc.net/";
            "jitsi" = "https://meet.jit.si/";
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.mobilizon.settings.":mobilizon"."Mobilizon.Web.Endpoint".http.port
  ];

  users.users.root.initialHashedPassword = "";

  virtualisation.memorySize = 1024;

  documentation = {
    man.enable = true;
  };
}
