{ inputs, ... }:
{
  # Only import DAO service modules from external flake
  imports = [
    inputs.dao-flake.nixosModules."dao-directory"
    inputs.dao-flake.nixosModules."dao-backend"
  ];
}
