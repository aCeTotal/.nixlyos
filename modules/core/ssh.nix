{ lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
      X11Forwarding = false;
      AllowTcpForwarding = "yes";
      AllowAgentForwarding = "yes";
      UseDns = false;
      ClientAliveInterval = 30;
      ClientAliveCountMax = 3;
      MaxAuthTries = 3;
      LoginGraceTime = "20s";
      Compression = "no";
      # Use per-option types expected by the OpenSSH module in 25.05.
      # - Ciphers, KexAlgorithms: list of strings
      # - MACs: string (comma-separated)
      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes256-ctr"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
      ];
    };
  };

  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host *
        ServerAliveInterval 20
        ServerAliveCountMax 3
        AddKeysToAgent yes
        ForwardAgent yes
    '';
  };
}
