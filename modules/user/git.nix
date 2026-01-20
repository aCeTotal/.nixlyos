{ pkgs, ... }:

{

    home.packages = with pkgs; [
        libsecret
        git-lfs
    ];

    programs.git = {
        enable = true;
        package = pkgs.gitFull;
        settings.user = {
            name = "aCeTotal";
            email = "lars.oksendal@gmail.com";
        };
    };

    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            compression = true;
          };
          "github.com" = {
            identityFile = "~/.ssh/github";
          };
        };
    };
}
