{ pkgs, users, inputs, system, ...}:

{
  imports = [
    ./clickonce.nix
  ];

  home.packages = with pkgs; [
    google-chrome
    kitty
    codex
    freecad
    bashmount udisks udiskie
    mpv 
    spotify
    zoxide
    pamixer
    ripgrep
    slurp grim swappy wl-clipboard
    nix-index

    #Work
    #teams-for-linux

    # blender (CUDA via stable HM set)
    
  ];
  
}
