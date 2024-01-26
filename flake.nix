{
  description = "OCaml lib and bin projects to get started with nix flakes.";

  inputs.nix-filter.url = "github:numtide/nix-filter";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.inputs.flake-utils.follows = "flake-utils";
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs.url = "github:nix-ocaml/nix-overlays";

  outputs = { self, nixpkgs, flake-utils, nix-filter }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}".extend (final: prev: {
          ocamlPackages = prev.ocaml-ng.ocamlPackages_5_1.overrideScope'
            (ofinal: oprev: rec {
              eio = with oprev;
                buildDunePackage rec {
                  pname = "eio";
                  version = "0.11";
                  minimalOCamlVersion = "5.0";

                  src = prev.fetchurl {
                    url =
                      "https://github.com/ocaml-multicore/${pname}/releases/download/v${version}/${pname}-${version}.tbz";
                    hash =
                      "sha256-DDN0IHRWJjFneIb0/koC+Wcs7JQpf/hcLthU21uqcao=";
                  };

                  propagatedBuildInputs = [
                    bigstringaf
                    cstruct
                    domain-local-await
                    fmt
                    hmap
                    lwt-dllist
                    mtime
                    optint
                    psq
                  ];

                  checkInputs = [ alcotest crowbar mdx ];

                  nativeCheckInputs = [ mdx.bin ];

                  meta = {
                    homepage =
                      "https://github.com/ocaml-multicore/ocaml-${pname}";
                    changelog =
                      "https://github.com/ocaml-multicore/ocaml-${pname}/raw/v${version}/CHANGES.md";
                    description = "Effects-Based Parallel IO for OCaml";
                    license = with prev.lib.licenses; [ isc ];
                    maintainers = with prev.lib.maintainers; [ toastal ];
                  };
                };

              eio_linux = oprev.eio_linux.override { eio = eio; };
              eio_posix = oprev.eio_posix.override { eio = eio; };
              eio_main = oprev.eio_main.override { eio = eio; };

              mirage-crypto = oprev.mirage-crypto.overrideAttrs (_: _: rec {
                version = "0.11.1";
                src = prev.fetchurl {
                  url =
                    "https://github.com/mirage/mirage-crypto/releases/download/v${version}/mirage-crypto-${version}.tbz";
                  sha256 =
                    "sha256-DNoUeyCpK/cMXJ639VxnXQOrx2u9Sx8N2c9/w4AW0pw=";
                };
              });

              mirage-crypto-rng = oprev.mirage-crypto-rng.override {
                mirage-crypto = mirage-crypto;
              };

              mirage-crypto-rng-eio = oprev.buildDunePackage {
                pname = "mirage-crypto-rng-eio";
                inherit (mirage-crypto) src version;
                dontDetectOcamlConflicts = true;
                propagatedBuildInputs = [ eio mirage-crypto-rng oprev.mtime ];
              };

              tls = oprev.tls.overrideAttrs (_: _: rec {
                version = "0.17.1";
                src = prev.fetchurl {
                  url =
                    "https://github.com/mirleft/ocaml-tls/releases/download/v${version}/tls-${version}.tbz";
                  hash = "sha256-gBDStt4UjaIoaSgYHSM71yD6YPoVez1CULyg3QCMXT8=";
                };
              });

              tls-eio = oprev.buildDunePackage {
                pname = "tls-eio";
                inherit (tls) src meta version;
                dontDetectOcamlConflicts = true;
                propagatedBuildInputs = [
                  tls
                  mirage-crypto-rng
                  mirage-crypto-rng-eio
                  oprev.x509
                  eio
                ];
              };

            });
        });
        opkgs = pkgs.ocamlPackages;
      in
      {
        devShells.default = pkgs.mkShell {
          dontDetectOcamlConflicts = true;
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
            eio
            eio_main
            ptime
            menhir
            menhirLib
            tls
            tls-eio
            ipaddr
            ca-certs
            x509
            ppxlib
            mirage-crypto-rng
            mirage-crypto-rng-eio
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
