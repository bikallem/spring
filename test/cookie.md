# Cookie tests

```ocaml
open Spring
```
## Cookie.decode - supports both " .. " and without

```ocaml
# let t = Cookie.decode "SID=31d4d96e407aad42; lang=en";;
val t : Cookie.t = <abstr>

# let t = Cookie.decode {|SID="31d4d96e407aad42"; lang="en"|};;
val t : Cookie.t = <abstr>
```

```ocaml
# Cookie.decode "";; 
Exception: Failure "Invalid \"cookie-pair\"".

# Cookie.decode "a";; 
Exception: End_of_file.
```

## Cookie.find_opt

```ocaml
# Cookie.find_opt "SID" t ;;
- : string option = Some "31d4d96e407aad42"

# Cookie.find_opt "lang" t ;;
- : string option = Some "en"

# Cookie.find_opt "asdfsa" t;;
- : string option = None
```

## Cookie.encode

```ocaml
# Cookie.encode t;;
- : string = "SID=31d4d96e407aad42; lang=en"
```

## Cookie.add

```ocaml
# let t = Cookie.add ~name:"id" ~value:"value1" t;;
val t : Cookie.t = <abstr>

# Cookie.find_opt "id" t;;
- : string option = Some "value1"

# Cookie.encode t;;
- : string = "SID=31d4d96e407aad42; id=value1; lang=en"
```

## Cookie.remove

```ocaml
# let t = Cookie.remove ~name:"id" t;;
val t : Cookie.t = <abstr>

# Cookie.find_opt "id" t;; 
- : string option = None
```
