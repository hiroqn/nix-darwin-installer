{
  description = "nix-darwin installer demo";
  inputs = {
    nix-darwin-installer.url = "github:hiroqn/nix-darwin-installer";
  };

  outputs =
    inputs@{
      nix-darwin-installer,
      ...
    }:
    {
      darwinConfigurations."default" = nix-darwin-installer.inputs.nix-darwin.lib.darwinSystem {
        modules = [
          nix-darwin-installer.darwinModules.default
          (
            { lib, pkgs, ... }:
            {
              system.stateVersion = 6;
              nixpkgs.hostPlatform = "aarch64-darwin";
            }
          )
        ];
      };
    };
}
