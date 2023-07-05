# Cookie tests

```ocaml
open Spring
```

```ocaml
let display_cookie name t =
    let pp_name_prefix = Fmt.(option ~none:(any "None") Cookie_name_prefix.pp) in
    Eio.traceln "Name: '%s'" name;
    Eio.traceln "NamePrefix: '%a'" pp_name_prefix @@ Cookie.name_prefix name t;
    Eio.traceln "Value : '%a'" Fmt.(option string) @@ Cookie.find_opt name t
```

## decode 

```ocaml
# let t0 = Cookie.decode "SID=31d4d96e407aad42; lang=en";;
val t0 : Cookie.t = <abstr>

# display_cookie "SID" t0;;
+Name: 'SID'
+NamePrefix: 'None'
+Value : '31d4d96e407aad42'
- : unit = ()

# display_cookie "lang" t0;;
+Name: 'lang'
+NamePrefix: 'None'
+Value : 'en'
- : unit = ()
```

Decode should preserve double quotes in cookie value.

```ocaml
# let t1 = Cookie.decode {|SID="31d4d96e407aad42"; lang="en"|};;
val t1 : Cookie.t = <abstr>

# display_cookie "SID" t1;;
+Name: 'SID'
+NamePrefix: 'None'
+Value : '"31d4d96e407aad42"'
- : unit = ()

# display_cookie "lang" t1;;
+Name: 'lang'
+NamePrefix: 'None'
+Value : '"en"'
- : unit = ()
```

Decode cookies with cookie name prefix.

```ocaml
# display_cookie "SID" @@ Cookie.decode {|__Host-SID=1234|};;
+Name: 'SID'
+NamePrefix: '__Host-'
+Value : '1234'
- : unit = ()

# display_cookie "SID" @@ Cookie.decode {|__Secure-SID=1234|};;
+Name: 'SID'
+NamePrefix: '__Secure-'
+Value : '1234'
- : unit = ()
```

1. Cookie name prefixes are case-sensitive in Cookie header. (Set-Cookie decoding is case-insensitive.)

```ocaml
# let t3 = Cookie.decode {|__SeCUre-SID=1234|};;
val t3 : Cookie.t = <abstr>

# display_cookie "__SeCUre-SID" t3;;
+Name: '__SeCUre-SID'
+NamePrefix: 'None'
+Value : '1234'
- : unit = ()

# Cookie.find_opt "__SeCUre-SID" t3;;
- : string option = Some "1234"
```

```ocaml
# Cookie.decode "";; 
Exception: Failure "take_while1".

# Cookie.decode "a";; 
Exception: End_of_file.
```

## is_empty

```ocaml
# Cookie.(is_empty empty);;
- : bool = true

# Cookie.is_empty t0;;
- : bool = false
```

## Cookie.find_opt

```ocaml
# Cookie.find_opt "SID" t0 ;;
- : string option = Some "31d4d96e407aad42"

# Cookie.find_opt "lang" t0 ;;
- : string option = Some "en"

# Cookie.find_opt "asdfsa" t0;;
- : string option = None
```

## Cookie.encode

```ocaml
# Cookie.encode t0;;
- : string = "SID=31d4d96e407aad42;lang=en"
```

Encode should preserve the double quotes in cookie value.

```ocaml
# Cookie.encode t1;;
- : string = "SID=\"31d4d96e407aad42\";lang=\"en\""
```

Encode should add cookie name prefix if it exists.

```ocaml
# Cookie.(add ~name_prefix:Cookie_name_prefix.host 
        ~name:"SID" 
        ~value:{|"1234"|} 
        empty)
  |> Cookie.add ~name:"nm1" ~value:"3333"
  |> Cookie.encode;;
- : string = "__Host-SID=\"1234\";nm1=3333"
```

## Cookie.add

```ocaml
# let t = Cookie.add ~name:"id" ~value:"value1" t0;;
val t : Cookie.t = <abstr>

# Cookie.find_opt "id" t;;
- : string option = Some "value1"

# Cookie.encode t;;
- : string = "SID=31d4d96e407aad42;id=value1;lang=en"
```

## Cookie.remove

```ocaml
# let t = Cookie.remove ~name:"id" t;;
val t : Cookie.t = <abstr>

# Cookie.find_opt "id" t;; 
- : string option = None
```
