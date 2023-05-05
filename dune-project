(lang dune 3.7)

(name spring)

(using menhir 2.1)

(using mdx 0.3)

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
   (>= 3.7.1))
  (easy-format
   (>= 1.3.4))
  (uri
   (>= 4.2.0))
  (ptime
   (>= 1.1.0))
  (astring
   (>= 0.8.5))
  (domain-name
   (>= 0.4.0))
  (menhir
   (>= 20230415))
  (cmdliner
   (>= 1.1.1))
  (ppxlib
   (>= 0.29.1))
  (eio_main
   (and
    (>= 0.9)
    :with-test))
  (fmt
   (and
    (>= 0.9.0)
    :with-test))
  (cstruct
   (and
    (>= 6.1.1)
    :with-test))
  (mdx
   (and
    (>= 2.3.0)
    :with-test))))
