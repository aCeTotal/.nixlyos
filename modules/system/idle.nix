{ ... }:

{
  # The screen never blanks and the machine never auto-suspends on idle; idle
  # locking is handled by the nixly-idled user service.
  #
  # Lid close = suspend-to-RAM (mem_sleep default is "deep"): the exact desktop
  # state stays in RAM at near-zero power, and opening the lid resumes straight
  # back into the session. Docked (external monitor) keeps ignoring the lid so
  # closing the laptop at a desk doesn't kill the session.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = 0;
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };
}
