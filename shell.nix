{ pkgs ? import <nixpkgs> {} }:



let
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-basic
      xcolor booktabs etoolbox footnotehyper xurl bookmark upquote csquotes sectsty;
  });
  python = (pkgs.python3.withPackages(py: [
    py.panflute
    py.parsy
    py.dateparser
  ]));
in
pkgs.mkShell {

  packages = [ python tex pkgs.pandoc pkgs.zlib pkgs.gcc pkgs.haskellPackages.pandoc pkgs.haskellPackages.cabal-install pkgs.ghc pkgs.pkg-config pkgs.coursier pkgs.haskellPackages.pandoc-plot pkgs.python3 pkgs.graphviz ];

  inputsFrom = [ ];
}
