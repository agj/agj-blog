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
        pkgs = import nixpkgs {system = system;};
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            elmPackages.elm
            elmPackages.elm-format
            elmPackages.elm-optimize-level-2
            elmPackages.elm-pages
            elmPackages.elm-review
            just
            leiningen
            nodejs_20
          ];
        };
      }
    );
}
