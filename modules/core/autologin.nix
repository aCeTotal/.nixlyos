{ ... }:

# Import this module for automatic login at boot; SDDM skips the greeter and
# starts the session as "total".
{
  services.displayManager.autoLogin = {
    enable = true;
    user = "total";
  };
}
