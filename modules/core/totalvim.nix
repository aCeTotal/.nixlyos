{ totalvimPkg, ... }:

{
  home-manager.sharedModules = [
    {
      home.packages = [ totalvimPkg ];
    }
  ];
}
