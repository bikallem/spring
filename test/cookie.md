# Cookie tests

```ocaml
open Spring
```
## Cookie.decode - supports both " .. " and without

```ocaml
# let t = Cookie.decode "SID=31d4d96e407aad42; lang=en";;
val t : Cookie.t = <abstr>

# let t = Cookie.decode {|SID="31d4d96e407aad42"; lang="en"|};;
```

```ocaml
# Cookie.decode "";; 
Exception: End_of_file.

# Cookie.decode "a";; 
Exception: End_of_file.
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
- : string = "SID=31d4d96e407aad42; lang=en"
```
