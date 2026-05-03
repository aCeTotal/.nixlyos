{ ... }:

{
  # Skjerm skal aldri slå seg av og maskinen skal aldri suspende automatisk.
  # Brukeren orkestrerer screensaver+lock i userspace via swayidle/hyprlock.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = 0;
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
}
