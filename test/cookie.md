# Cookie tests

```ocaml
open Spring
```
## Cookie.decode

```ocaml
# let t = Cookie.decode "SID=31d4d96e407aad42; lang=en";;
val t : Cookie.t = [("lang", "en"); ("SID", "31d4d96e407aad42")]
```
