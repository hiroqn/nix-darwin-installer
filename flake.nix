{
  description = "nix-darwin installer demo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      nix-darwin,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
      ];

      imports = [
        (
          { lib, ... }:
          {
            perSystem =
              {
                config,
                pkgs,
                system,
                ...
              }:
              {
                _module.args.pkgs = import nixpkgs {
                  inherit system;
                };
              };
          }
        )
      ];

      flake = {
        darwinModules.default =
          { pkgs, ... }:
          {
            config = {
              programs.bash.enable = true;
              programs.zsh.enable = true;
              system.activationScripts.checks.text = "";
              nixpkgs.source = nixpkgs;
              nixpkgs.overlays = [
                (final: prev: {
                  nix = prev.nixVersions.nix_2_29;
                })
              ];
              # flake registryの設定
              nixpkgs.flake.source = nixpkgs;
            };
          };
      };

      perSystem =
        { pkgs, system, ... }:
        let
          nix-src = pkgs.applyPatches {
            name = "nix-source";
            src = pkgs.fetchFromGitHub {
              owner = "NixOS";
              repo = "nix";
              rev = "2.29.2";
              sha256 = "sha256-50p2sG2RFuRnlS1/Vr5et0Rt+QDgfpNE2C2WWRztnbQ=";
            };
            patches = [ ./installer.patch ];
          };

        in
        {
          packages = {
            installer = pkgs.callPackage "${nix-src}/packaging/binary-tarball.nix" {
              nix = pkgs.nixVersions.nix_2_29;
              inherit system self;
              darwinSystem = nix-darwin.lib.darwinSystem {
                inherit system;
                modules = [
                  self.darwinModules.default
                  (
                    { lib, pkgs, ... }:
                    {
                      # $ darwin-rebuild changelog
                      system.stateVersion = 6;
                    }
                  )
                ];
              };
            };
          };
          formatter = pkgs.nixfmt-tree;
        };
    };
}
