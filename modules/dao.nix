{ lib, config, pkgs, inputs, ... }:
let
  backend = config.services.dao-backend;
in
{
  # Pull in DAO service option definitions from external flake
  imports = [
    inputs.dao-flake.nixosModules."dao-directory"
    inputs.dao-flake.nixosModules."dao-backend"
  ];

  # Directory service
  services.dao-directory = {
    enable = true;
    listenHost = "0.0.0.0";
    listenPort = 5560;
    ttlMs = 10000;
    logLevel = "debug";
  };

  # Backend service
  services.dao-backend = {
    enable = true;
    listenHost = "0.0.0.0";
    listenPort = 5555;
    authToken = "devtoken";
    logLevel = "debug";
  };

  # Ensure backend picks up directory settings via config file
  environment.etc."dao/dao.conf".text = lib.mkForce ''
    listen_host=${backend.listenHost}
    listen_port=${toString backend.listenPort}
    auth_token=${backend.authToken}
    node_id=0
    log_level=${backend.logLevel}
    directory_enable=true
    directory_host=127.0.0.1
    directory_port=5560
  '';

  networking.firewall.allowedTCPPorts = [ 5555 5560 ];
}

