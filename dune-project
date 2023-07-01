(lang dune 3.8)

(name spring)

(using menhir 2.1)

(using mdx 0.4)

(generate_opam_files true)

(source
 (github gbikal/spring))

(authors "Bikal Gurung")

(maintainers "gbikal@gmail.com")

(license MPL-2.0)

(package
 (name spring)
 (synopsis "Web programming library")
 (description "A delightful web programming library")
 (depends
  (ocaml
   (>= 5.0.0))
  (eio
   (>= 0.9))
  (dune
   (>= 3.8.2))
  (easy-format
   (>= 1.3.4))
  (uri
   (>= 4.2.0))
  (ptime
   (>= 1.1.0))
  (astring
   (>= 0.8.5))
  (fmt
   (>= 0.9.0))
  (domain-name
   (>= 0.4.0))
  (menhir
   (>= 20230608))
  (cmdliner
   (>= 1.1.1))
  (ppxlib
   (>= 0.29.1))
  (cstruct
   (>= 6.2.0))
  (base64
   (>= 3.5.1))
  (eio_main
   (>= 0.9))
  (csexp
   (>= 1.5.2))
  (mirage-crypto
   (>= 0.11.1))
  (mirage-crypto-rng
   (>= 0.11.1))
  (mirage-crypto-rng-eio
   (>= 0.11.1))
  (fpath
   (>= 0.7.3))
  (magic-mime
   (>= 1.3.0))
  (cstruct
   (and
    (>= 6.1.1)
    :with-test))
  (mdx
   (and
    (>= 2.3.0)
    :with-test))))
