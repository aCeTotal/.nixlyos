{ lib, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      # Make Kitty background fairly transparent without changing color palette
      background_opacity = lib.mkForce "0.75"; # ensure this overrides any defaults
      dynamic_background_opacity = true;
    };
  };
}
