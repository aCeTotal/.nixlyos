{ ... }:

{
    # Bash
    programs = {
        bash = {
            enable = true;
            enableCompletion = true;

            shellAliases = {
                "z" = "zoxide";
            };
        };
        direnv = {
            enable = true;
            nix-direnv.enable = true;
        };
    };
}
