{
  description = "OCaml lib and bin projects to get started with nix flakes.";

  # inputs.nix-filter.url = "github:numtide/nix-filter";
  # inputs.flake-utils.url = "github:numtide/flake-utils";
  # inputs.nixpkgs.inputs.flake-utils.follows = "flake-utils";
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.flake-utils.follows = "flake-utils";
    };
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}".extend (self: super: {
          ocamlPackages = super.ocaml-ng.ocamlPackages_5_1.overrideScope'
            (oself: osuper: {
              eio = osuper.eio.overrideAttrs (_: _: rec {
                version = "0.11";
                src = self.fetchurl {
                  url =
                    "https://github.com/ocaml-multicore/eio/releases/download/v${version}/eio-${version}.tbz";
                  hash = "sha256-DDN0IHRWJjFneIb0/koC+Wcs7JQpf/hcLthU21uqcao=";
                };
              });

              # eio_linux = opkgs.eio_linux.override { eio = eio; };
              # eio_posix = opkgs.eio_posix.override { eio = eio; };
              # eio_main = opkgs.eio_main.override {
              #   eio = eio;
              #   eio_posix = eio_posix;
              #   eio_linux = eio_linux;
              # };

              # mirage-crypto = opkgs.mirage-crypto.overrideAttrs (_: _: rec {
              #   version = "0.11.1";
              #   src = pkgs.fetchurl {
              #     url =
              #       "https://github.com/mirage/mirage-crypto/releases/download/v${version}/mirage-crypto-${version}.tbz";
              #     sha256 =
              #       "sha256-DNoUeyCpK/cMXJ639VxnXQOrx2u9Sx8N2c9/w4AW0pw=";
              #   };
              # });

              # mirage-crypto-rng = opkgs.mirage-crypto-rng.override {
              #   mirage-crypto = mirage-crypto;
              #   # mtime = mtime;
              # };

              # mirage-crypto-rng-eio = opkgs.buildDunePackage {
              #   pname = "mirage-crypto-rng-eio";
              #   inherit (mirage-crypto) src version;
              #   propagatedBuildInputs = [ eio mirage-crypto-rng opkgs.mtime ];
              # };

              # tls = opkgs.tls.overrideAttrs (_: _: rec {
              #   version = "0.17.1";
              #   src = pkgs.fetchurl {
              #     url =
              #       "https://github.com/mirleft/ocaml-tls/releases/download/v${version}/tls-${version}.tbz";
              #     hash = "sha256-gBDStt4UjaIoaSgYHSM71yD6YPoVez1CULyg3QCMXT8=";
              #   };
              # });

              # tls-eio = opkgs.buildDunePackage {
              #   pname = "tls-eio";
              #   inherit (tls) src meta version;
              #   propagatedBuildInputs = [
              #     tls
              #     mirage-crypto-rng
              #     mirage-crypto-rng-eio
              #     opkgs.x509
              #     eio
              #   ];
              # };

            });
        });

        opkgs = pkgs.ocamlPackages;

      in {
        devShells.default = pkgs.mkShell {
          # dontDetectOcamlConflicts = true;
          nativeBuildInputs = with opkgs; [
            dune_3
            utop
            ocaml
            mdx
            odoc
            ocamlformat
            findlib
          ];

          packages = with opkgs; [
            logs
            # eio
            # eio_main
            ptime
            menhir
            menhirLib
            tls
            # tls-eio
            ipaddr
            ca-certs
            x509
            ppxlib
            # mirage-crypto-rng
            # mirage-crypto-rng-eio
            astring
            base64
            cmdliner
            domain-name
            fmt
            cstruct
            magic-mime
            fpath
          ];
        };
      });
}
