{ ... }:

# Importér denne modulen for automatisk innlogging ved boot.
# SDDM hopper over login-skjermen og starter sesjonen som "total".
{
  services.displayManager.autoLogin = {
    enable = true;
    user = "total";
  };
}
