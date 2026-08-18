{ pkgs, ... }:

{
  # Live speiling av Android-skjerm i et vindu på maskinen (scrcpy).
  # Lav latency, og mus/tastatur styrer telefonen.
  #
  # Krever USB-feilsøking på telefonen: Innstillinger → Om telefonen →
  # trykk "Byggnummer" 7x → Utvikleralternativer → USB-feilsøking.
  #
  #   scrcpy                          USB — godkjenn dialogen på telefonen
  #   adb tcpip 5555                  bytt til wifi (kabel fortsatt i)
  #   adb connect <telefon-ip>:5555   deretter kan kabelen tas ut
  #
  # Nyttige flagg: --max-size 1920 --max-fps 60 --turn-screen-off --stay-awake

  # programs.adb/adbusers-gruppa er fjernet i nixpkgs — systemd 258 gir
  # uaccess på USB-enheten selv, så adb trenger bare å ligge i PATH.
  environment.systemPackages = with pkgs; [
    scrcpy
    android-tools # adb
  ];
}
