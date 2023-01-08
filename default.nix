let
  sources = import ./nix/sources.nix { };
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.elmPackages.elm
    pkgs.elmPackages.elm-format
    pkgs.elmPackages.elm-optimize-level-2
    pkgs.elmPackages.elm-pages
    pkgs.elmPackages.elm-review
    pkgs.nodejs
  ];
}