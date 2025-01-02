{
  description = "Blog";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true;
        };
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-optimize-level-2
            pkgs.elmPackages.elm-review
            pkgs.elmPackages.lamdera
            pkgs.just
            pkgs.leiningen
            pkgs.nodejs_20
            pkgs.pnpm

            # Currently broken:
            # pkgs.elmPackages.elm-format
          ];
        };
      }
    );
}
