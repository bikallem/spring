# Cache-Control

```ocaml
open Spring
```

## add/find_opt/find

Test that we can add, find `max_age` and `no-cache` directive.

```ocaml
# Cache_control.(find_opt max_age empty);;
- : int option = None

# let t1 = Cache_control.(add ~v:5 max_age empty);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find_opt max_age t1);;
- : int option = Some 5

# Cache_control.(find_opt no_cache t1);;
- : bool option = None

# Cache_control.(find no_cache t1);;
- : bool = false

# let t1 = Cache_control.(add no_cache t1);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find_opt no_cache t1);;
- : bool option = Some true

# Cache_control.(find no_cache t1);;
- : bool = true
```

## decode

```ocaml
let s ="max-age=604800, must-revalidate, no-store, private, public";;
```

```ocaml
# let t2 = Cache_control.decode s;
val t2 : Cache_control.t = <abstr>

# Cache_control.(find_opt max_age t2);;
- : int option = Some 604800

# Cache_control.decode "";;
Exception: Failure "take_while1".
```

Decoding correctly takes whitespaces before/after `,'.

```ocaml
# Cache_control.decode "max-age=604800,    must-revalidate, no-store,private   , public";;
- : Cache_control.t = <abstr>
```

## encode

```ocaml
# let s1 = Cache_control.encode t2;;
val s1 : string =
  "max-age=604800, must-revalidate, no-store, private, public"

# s1 = s;;
- : bool = true
```
