# Cookie tests

```ocaml
open Spring
```
## Cookie.decode

```ocaml
# let t = Cookie.decode "SID=31d4d96e407aad42; lang=en";;
val t : Cookie.t = <abstr>

# Cookie.decode "";; 
Exception: Invalid_argument "[Cookie.decode] argument [v] is empty".

# Cookie.decode "a";; 
Exception: Invalid_argument "[Cookie.decode] argument [v] is invalid".
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

## Cookie.encode

```ocaml
# Cookie.encode t;;
- : string = "lang=en; SID=31d4d96e407aad42"
```
