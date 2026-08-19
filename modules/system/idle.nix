{ ... }:

{
  # The screen never blanks and the machine never auto-suspends; idle locking is
  # handled by the nixly-idled user service.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = 0;
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
}
