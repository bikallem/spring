{ pkgs ? import <nixpkgs> { } }:

let
  onix = import (builtins.fetchGit {
    url = "https://github.com/rizo/onix.git";
    rev = "a5de90d3437848d048ed73b7e9aa18fb57702ae7";
  }) {
    inherit pkgs;
    verbosity = "info";
  };

in onix.env {
  path = ./.;
  repos = [{
    url = "https://github.com/ocaml/opam-repository.git";
    rev = "d45d933f2f08ca7f2b61f60dbef34930e1d5194b";
  }];
  deps = {
    "ocaml-variants" = "5.1.0+options";
    "ocaml-option-afl" = "*";
  };
  vars = {
    "with-test" = true;
    "with-doc" = true;
    "with-dev-setup" = true;
  };
}
