{ ... }:

{
  # Skjerm skal aldri slå seg av og maskinen skal aldri suspende automatisk.
  # Idle-lock håndteres av nixly_lockscreen sin nixly-idled user-service.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = 0;
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
}
