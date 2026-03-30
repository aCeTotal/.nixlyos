{ inputs, system, ... }:

{
  home-manager.sharedModules = [
    {
      home.packages = [
        inputs.totalvim.packages.${system}.default
      ];
    }
  ];
}
