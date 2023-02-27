# Cookie tests

```ocaml
open Spring
```
## Cookie.decode

```ocaml
# let t = Cookie.decode "SID=31d4d96e407aad42; lang=en";;
val t : Cookie.t = <abstr>
```

## Cookie.find

```ocaml
# Cookie.find t "SID";;
- : string option = Some "31d4d96e407aad42"

# Cookie.find t "lang" ;;
- : string option = Some "en"

# Cookie.find t "asdfsa";;
- : string option = None
```
