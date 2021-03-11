{ config, pkgs, ... }:

{
  fileSystems."/".label = "vmdisk";
  networking.hostName = "vmHost";

  services.mobilizon = {
    enable = true;
    settings = {
      ":mobilizon" = {
        ":instance" = {
          name = "Test Mobilizon";
          hostname = "mobilizon.org";
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
