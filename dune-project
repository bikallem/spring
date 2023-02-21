(lang dune 3.6)

(name spring)

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
   (>= 0.8.1))
  (dune
   (>= 3.6))
  (easy-format
   (>= 1.3.4))
  (uri
   (>= 4.2.0))
  (ptime
   (>= 1.1.0))
  (mdx
   (and
    (>= 2.2.1)
    :with-test))))
