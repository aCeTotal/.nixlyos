{

  programs.neovim.defaultEditor = true;

  # Power Management
  powerManagement.cpuFreqGovernor = "powersave";


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    # Use the default ssh-agent for stability; avoid conflict
    enableSSHSupport = false;
  };
  programs.dconf.enable = true;

  security.rtkit.enable = true;
  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.fstrim.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Auto-unlock GNOME Keyring via PAM for ly (DM) and TTY login
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;




}
