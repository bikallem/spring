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

1. Parse cookie-name prefix. The matching is case sensitive.
2. Display name_prefix.

```ocaml
# Cookie.decode {|__Host-SID=1234|} |> Cookie.name_prefix "SID";;
- : string option = Some "__Host-"

# Cookie.decode {|__Secure-SID=1234|} |> Cookie.name_prefix "SID";;
- : string option = Some "__Secure-"
```

1. Cookie name prefixes are case-sensitive in Cookie header. (Set-Cookie decoding is case-insensitive.)
2. If cookie-name-prefix is not matched, then it becomes part of the cookie name.

```ocaml
# let t = Cookie.decode {|__SeCUre-SID=1234|};;
val t : Cookie.t = <abstr>

# Cookie.name_prefix "SID" t;;
- : string option = None

# Cookie.find_opt "__SeCUre-SID" t;;
- : string option = Some "1234"
```

```ocaml
# Cookie.decode "";; 
Exception: Failure "take_while1".

# Cookie.decode "a";; 
Exception: End_of_file.
```

## Cookie.find_opt

```ocaml
# Cookie.find_opt "SID" t ;;
- : string option = None

# Cookie.find_opt "lang" t ;;
- : string option = None

# Cookie.find_opt "asdfsa" t;;
- : string option = None
```

## Cookie.encode

```ocaml
# Cookie.encode t;;
- : string = "__SeCUre-SID=1234"
```

Encode should add cookie name prefix if it exists.

```ocaml
# Cookie.(add ~name_prefix:"__Host-" ~name:"SID" ~value:{|"1234"|} empty)
  |> Cookie.add ~name:"nm1" ~value:"3333"
  |> Cookie.encode;;
- : string = "__Host-SID=\"1234\"; nm1=3333"
```

## Cookie.add

```ocaml
# let t = Cookie.add ~name:"id" ~value:"value1" t;;
val t : Cookie.t = <abstr>

# Cookie.find_opt "id" t;;
- : string option = Some "value1"

# Cookie.encode t;;
- : string = "__SeCUre-SID=1234; id=value1"
```

## Cookie.remove

```ocaml
# let t = Cookie.remove ~name:"id" t;;
val t : Cookie.t = <abstr>

# Cookie.find_opt "id" t;; 
- : string option = None
```
